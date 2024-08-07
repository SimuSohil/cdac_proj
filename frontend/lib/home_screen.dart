import 'package:cdac_design/bottomNavBar/call_logs.dart';
import 'package:cdac_design/bottomNavBar/contacts.dart';
import 'package:cdac_design/bottomNavBar/vishing_data.dart';
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
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the key here to the Scaffold
      appBar: AppBar(
        backgroundColor: const Color(0xff4E66AB),
        title: const Text(
          'Anti-Vishing Application',
          style: TextStyle(fontWeight: FontWeight.w400, color: Color(0xffFFFFFF)),
        ),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: const Icon(Icons.menu, color: Color(0xffFFFFFF)),
        ),
      ),
      drawer: Drawer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView(
                children: const <Widget>[
                  DrawerHeader(decoration: BoxDecoration(color: Color(0xff5F67B1)),child: Text('User Details', style: TextStyle(fontWeight: FontWeight.bold),),),
                  ListTile(
                    leading: Icon(Icons.perm_contact_cal_sharp),
                    title: Text('Profile'),
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About'),
                  ),
                  Divider()
                ],
              ),
            ),
            const ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
            )
          ],
        ),
      ),
      body: _widgetOptions[_currentPage],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: const Color(0xff4E66AB),
        items: const <TabItem>[
          TabItem(icon: Icon(Icons.dangerous_outlined), title: 'Vishing Threats'),
          TabItem(icon: Icon(Icons.call), title: 'Call Logs'),
          TabItem(icon: Icon(Icons.contacts_rounded), title: 'Contacts'),
          // TabItem(icon: Icon(Icons.settings), title: 'Settings'),
        ],
        onTap: (int index) {
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
