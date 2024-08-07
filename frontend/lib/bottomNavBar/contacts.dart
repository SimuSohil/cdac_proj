import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'contacts_details.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  static List<Contact> _contacts = [];
  // ignore: unused_field
  static Map<String, Contact> _contactsMap = {};
  static bool _contactsFetched = false; // Flag to check if contacts are already fetched
  final _contactsStreamController = StreamController<List<Contact>>.broadcast();
  final TextEditingController _searchController = TextEditingController();
  bool isFilterApplied = false;
  String searchQuery = '';

  List<Contact> contacts = [];
  List<Contact> displayedContacts = [];
  List<Contact> filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _contactsStreamController.close();
    _searchController.clear();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    // Request contacts permission
    PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus == PermissionStatus.granted) {
      log('Contacts permission granted');
      await _fetchContacts(); // Fetch contacts immediately after permission is granted
    } else {
      // Handle permission denied
      log('Contacts permission denied');
    }
  }

  Future<void> _fetchContacts() async {
    try {
      PermissionStatus permissionStatus = await Permission.contacts.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.contacts.request();
      }

      if (permissionStatus.isGranted) {
        log('Permission status: granted');
        if (!_contactsFetched) {
          log('Fetching contacts...');
          Iterable<Contact> contacts = await ContactsService.getContacts(withThumbnails: true);
          _contacts = contacts.toList();
          _contactsFetched = true;

          _contactsMap = {
            for (var contact in _contacts)
              for (var phone in contact.phones!)
                _normalizePhoneNumber(phone.value!): contact
          };

          log('Contacts fetched: ${_contacts.length}');
          _contactsMap.forEach((key, value) {
            log('Stored contact: $key -> ${value.displayName}');
          });
          log('Contacts fetched successfully');
          _contactsStreamController.sink.add(_contacts);
        } else {
          log('Using cached contacts');
          _contactsStreamController.sink.add(_contacts);
        }
      } else {
        log('Contacts permission denied');
      }
    } catch (e) {
      log('Error fetching contacts: $e');
    }
  }

  String _normalizePhoneNumber(String phoneNumber) {
    // Remove non-numeric characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // Remove leading country code if present
    if (normalized.length > 10 &&
        (normalized.startsWith('91') || normalized.startsWith('+91'))) {
      normalized = normalized.substring(normalized.length - 10);
    }
    return normalized;
  }

  void _clearFilter() {
    setState(() {
      isFilterApplied = false;
      searchQuery = '';
      filteredContacts = _contacts;
    });
  }

  void _applyFilter(String query) {
    setState(() {
      searchQuery = query;
      isFilterApplied = true;
      filteredContacts = _contacts.where((contact) {
        return contact.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false;
      }).toList();
    });
  }

  Future<void> _loadContacts() async {
    try {
      Iterable<Contact> entries = await ContactsService.getContacts(withThumbnails: true);
      setState(() {
        contacts = entries.toList();
        displayedContacts = contacts;
        _contactsFetched = true;
      });
      _contactsStreamController.sink.add(contacts);
    }
    catch (e){
      log('Error loading the contacts $e');
    }
  }

  Future<void> _refreshData() async { 
    await _loadContacts(); // Reload call logs
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          Container(
            color: const Color(0xff4E66AB),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Contacts',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff4E66AB)), // Darker border color
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xff4E66AB)), // Darker border color when enabled
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.white), // Darker icon color
                  filled: true,
                  fillColor: Color(0xff4E66AB), // Light grey background color
                  contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                ),
                style: const TextStyle(color: Colors.black), // Darker text color
                onChanged: (query) {
                  if (query.isEmpty) {
                    _clearFilter();
                  } else {
                    _applyFilter(query);
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xff4E66AB), Color(0xffFFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<List<Contact>>(
                  stream: _contactsStreamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<Contact> contacts = isFilterApplied ? filteredContacts : snapshot.data!;
                      return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          Contact contact = contacts[index];
                          return Card(
                            elevation: 4.0,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10.0),
                              leading: CircleAvatar(
                                backgroundColor: Colors.black,
                                backgroundImage: contact.avatar != null &&
                                        contact.avatar!.isNotEmpty
                                    ? MemoryImage(Uint8List.fromList(
                                        contact.avatar!.toList()))
                                    : null,
                                child: (contact.avatar == null ||
                                        contact.avatar!.isEmpty)
                                    ? Text(
                                        contact.displayName?.isNotEmpty ?? false
                                            ? contact.initials()
                                            : 'NA',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      )
                                    : null,
                              ),
                              title: Text(contact.displayName ?? ''),
                              subtitle: Text(
                                contact.phones?.isNotEmpty ?? false
                                    ? contact.phones!.first.value ?? ''
                                    : '',
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactDetailScreen(
                                        contact: contact),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
