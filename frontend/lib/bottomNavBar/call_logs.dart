import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  List<CallLogEntry> callLogs = [];
  List<CallLogEntry> displayedLogs = []; // List to be displayed

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadCallLogs();
  }

  Future<void> _checkPermissionAndLoadCallLogs() async {
    if (await Permission.phone.request().isGranted) {
      _loadCallLogs();
    } else {
      showToast("Please provide phone permission");
      openAppSettings();
    }
  }

  Future<void> _loadCallLogs() async {
    Iterable<CallLogEntry> entries = await CallLog.get();
    setState(() {
      callLogs = entries.toList();
      displayedLogs = callLogs; // Initialize displayedLogs
    });
  }

  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xff4E66AB), Color(0xffFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: displayedLogs.length,
          itemBuilder: (context, index) {
            final CallLogEntry log = displayedLogs[index];
            Color iconColor;
            IconData leadingIcon;

            if (log.callType == CallType.incoming) {
              iconColor = Colors.blue;
              leadingIcon = Icons.call_received;
            } else if (log.callType == CallType.outgoing) {
              iconColor = Colors.green;
              leadingIcon = Icons.call_made;
            } else if (log.callType == CallType.missed) {
              iconColor = Colors.red;
              leadingIcon = Icons.call_missed;
            } else {
              iconColor = Colors.black; // Default color for unknown types
              leadingIcon = Icons.call; // Default icon for unknown types
            }

            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // Rounded corners
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0), // Add padding inside the ListTile
                leading: Icon(
                  leadingIcon,
                  color: iconColor,
                ),
                title: Text('${log.name ?? 'Unknown'} : ${log.number ?? 'Unknown'}'),
                subtitle: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration: ${_formatDuration(log.duration)} | Time: ${_formatTime(log.timestamp)}',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadCallLogs(); // Reload call logs
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return 'Unknown';
    final Duration duration = Duration(seconds: seconds);
    return duration.toString().split('.').first.padLeft(8, "0");
  }

  String _formatTime(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      return 'Unknown';
    }
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }
}
