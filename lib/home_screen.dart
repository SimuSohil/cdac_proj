import 'package:cdac_design/bottomNavBar/call_logs.dart';
import 'package:cdac_design/bottomNavBar/contacts.dart';
import 'package:cdac_design/bottomNavBar/vishing_data.dart';
// import 'package:cdac_design/phone_state.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const VishingPage(),
    const CallLogsScreen(),
    const ContactsPage(),
    // const LogsClass(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anti-Vishing Application', style: TextStyle(fontWeight: FontWeight.w400, color: Color(0xffFFFFFF)),), backgroundColor: Color(0xff4E66AB),),
      body: _widgetOptions[_currentPage],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: const Color(0xff4E66AB),
        items: const <TabItem>[
          TabItem(icon: Icon(Icons.dangerous_outlined), title: 'Vishing Threats'),
          TabItem(icon: Icon(Icons.call), title: 'Call Logs'),
          TabItem(icon: Icon(Icons.contacts_rounded), title: 'Contacts'),
          // TabItem(icon: Icon(Icons.settings), title: 'Settings'),
        ],
        onTap: (int index){
          setState(() {
            _currentPage = index;
          });
        },
        initialActiveIndex: _currentPage,
        style: TabStyle.reactCircle,
        height: 60,
      ),
    );
  }
}