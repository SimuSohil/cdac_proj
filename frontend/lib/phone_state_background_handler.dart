import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'spam_num_verify.dart';
import 'alert_box.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as alert;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AlertBoxSection(),
    ),
  );
}
Future<void> phoneStateBackgroundCallbackHandler(
  PhoneStateBackgroundEvent event,
  String number,
  int duration,
) async {
  log('Received event: $event, number: $number, duration: $duration s');

  await PhoneStateBackgroundHandler.ensureContactsFetched();

  String? contactName = await PhoneStateBackgroundHandler.getContactName(number);
  String contactStatus = contactName != null ? "Known: $contactName" : "Unknown";
  log('Contact status for number $number: $contactStatus');

  bool isSpam = await reportSpamNumber(number);

  String notificationMessage = contactName == null ? (isSpam ? 'Incoming call from $number (SPAM-ALERT)': 'Incoming call from $number (Unknown)') : contactStatus;
  
  String mainNotificationMessage = isSpam ? 'SPAM-NUMBER' : 'Unknown Number $number';

  await PhoneStateBackgroundHandler.showNotification(mainNotificationMessage, notificationMessage);

  // Notify only for incoming calls
  if (event == PhoneStateBackgroundEvent.incomingreceived ||
      event == PhoneStateBackgroundEvent.incomingstart ||
      event == PhoneStateBackgroundEvent.incomingmissed) {
    await PhoneStateBackgroundHandler.showNotification(
        mainNotificationMessage, notificationMessage);

    if (event == PhoneStateBackgroundEvent.incomingreceived &&
        contactName == null &&
        !isSpam) {
      log('Unknown call answered, sending voice file to API...');
      await PhoneStateBackgroundHandler.sendVoiceFileToAPI();
    }
  }

  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      log('Incoming call start, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      log('Incoming call missed, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      log('Incoming call received, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingend:
      log('Incoming call ended, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      log('Outgoing call start, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      log('Outgoing call ended, number: $number, duration: $duration s ($contactStatus)');
      break;
  }
}

class PhoneStateBackgroundHandler {
  static bool hasPermission = false;
  static Map<String, Contact> _contactsMap = {};
  static bool _contactsFetched = false;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      _isInitialized = true; // Set the flag to true after initialization
      log('Notifications initialized successfully');
    } catch (e) {
      log('Failed to initialize notifications: $e');
    }
  }

  static Future<void> askForPermissionIfNeeded(BuildContext context) async {
    try {
      final permission = await PhoneStateBackground.checkPermission();
      if (!permission) {
        await PhoneStateBackground.requestPermissions();
        hasPermission = await PhoneStateBackground.checkPermission();
      } else {
        hasPermission = true;
      }

      if (hasPermission) {
        await fetchContacts();
        _contactsFetched = true;
      }
    } catch (e) {
      log('Failed to ask for permission or fetch contacts: $e');
    }
  }

  static Future<void> ensureContactsFetched() async {
    if (!_contactsFetched) {
      log('Contacts not fetched yet. Fetching...');
      await fetchContacts();
      _contactsFetched = true;
    }
  }

  static Future<void> fetchContactsAndInit() async {
    await ensureContactsFetched();
    // await init();
    await initialize();
  }

  static Future<void> fetchContacts() async {
    try {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      log('Fetched ${contacts.length} contacts');

      _contactsMap = {
        for (var contact in contacts)
          for (var phone in contact.phones!)
            normalizePhoneNumber(phone.value!): contact
      };

      log('Normalized contacts fetched: ${_contactsMap.length}');
      _contactsMap.forEach((key, value) {
        log('Stored contact: $key -> ${value.displayName}');
      });

      if (_contactsMap.isEmpty) {
        log('No contacts fetched. Retrying...');
        await fetchContacts();
      } else {
        log('Contacts fetched successfully');
      }
    } catch (e) {
      log('Error fetching contacts: $e');
    }
  }

  static String normalizePhoneNumber(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (normalized.length > 10) {
      normalized = normalized.substring(normalized.length - 10);
    }
    log('Normalized phone number: $normalized');
    return normalized;
  }

  static Future<String?> getContactName(String phoneNumber) async {
    String normalizedNumber = normalizePhoneNumber(phoneNumber);
    log('Looking up contact for normalized number: $normalizedNumber');
    if (_contactsMap.containsKey(normalizedNumber)) {
      Contact contact = _contactsMap[normalizedNumber]!;
      log('Found contact: ${contact.displayName} for number: $normalizedNumber');
      return contact.displayName;
    } else {
      log('No contact found for number: $normalizedNumber');
      return null;
    }
  }

  static Future<bool> isContact(String phoneNumber) async {
    String normalizedIncomingNumber = normalizePhoneNumber(phoneNumber);
    log('Normalized incoming number: $normalizedIncomingNumber');

    log('_contactsMap contents:');
    _contactsMap.forEach((number, contact) {
      log('  $number: ${contact.displayName}');
    });

    log('_contactsMap size: ${_contactsMap.length}');

    return _contactsMap.containsKey(normalizedIncomingNumber);
  }

  static Future<void> init() async {
    try {
      log('Starting PhoneStateBackground initialization...');
      await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
      log('PhoneStateBackground initialized successfully');
    } catch (e) {
      log('Failed to initialize PhoneStateBackground: $e');
    }
  }

  static Future<void> stop() async {
    await PhoneStateBackground.stopPhoneStateBackground();
  }

  static Future<void> showNotification(String title, String body) async {
    await ensureInitialized(); // Add this line
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', // Ensure this matches the channel ID used in showNotification
      'your_channel_name',
      channelDescription: 'Your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // New method to send the voice file to the API
  static Future<void> sendVoiceFileToAPI() async {
    const String apiUrl = 'http://10.0.2.2:5000/upload';
    const String assetFilePath = 'assets/test.mp3';

    try {
      final ByteData byteData = await rootBundle.load(assetFilePath);

      final tempDir = await getTemporaryDirectory();

      final File tempFile = File('${tempDir.path}/test.mp3');

      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', tempFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        log('Voice file sent successfully.');
        var res = await response.stream.bytesToString();
        final jsonResponse = json.decode(res);
        log(jsonResponse['phishing_count'].toString());
        log(jsonResponse['phishing_percentage'].toString());
        if (jsonResponse['phishing_percentage'] > 15 ){
          () async {
                if (await alert.FlutterOverlayWindow.isActive()) return;
                await alert.FlutterOverlayWindow.showOverlay(
                  enableDrag: true,
                  overlayTitle: "X-SLAYER",
                  overlayContent: 'Overlay Enabled',
                  flag: alert.OverlayFlag.defaultFlag,
                  visibility: alert.NotificationVisibility.visibilityPublic,
                  positionGravity: alert.PositionGravity.auto,
                  height: alert.WindowSize.matchParent,
                  width: alert.WindowSize.matchParent,
                  startPosition: const alert.OverlayPosition(0, -259),
                );
              };
          log('scam');
        }
      } else {
        log('Failed to send voice file. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending voice file to API: $e');
    }
  }

  Future<void> requestOverlayPermission() async {
    if (!await alert.FlutterOverlayWindow.isPermissionGranted()) {
      log('not granted');
      await alert.FlutterOverlayWindow.requestPermission();
    }
  }

  // static void showOverlay() {
  //   log("overlay");
  //   FlutterOverlayWindow.showOverlay(
  //     height: 100,
  //     width: 200,
  //     alignment: OverlayAlignment.center,
  //     overlayTitle: 'Scam number',
  //     overlayContent: 'Scam!'
  //   );
  // }
}

