import 'package:flutter/material.dart';

class VishingPage extends StatefulWidget {
  const VishingPage({super.key});

  @override
  State<VishingPage> createState() => AVishingStatePage();
}

class AVishingStatePage extends State<VishingPage> {
  final List<String> vishingThreats = [
    '+1234567890',
    '+1987654321',
    '+1122334455',
    '+1231231234',
    '+9876543210',
    '+1234567890',
    '+1987654321',
    '+1122334455',
    '+1231231234',
    '+9876543210',
    '+15556667777',
    '+14443332222',
    '+16667778888',
    '+19990001111',
    '+12223334444',
    '+17778889999',
    '+13334445555',
    '+18889990000',
    '+14445556666',
    '+15556667777'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xff4E66AB), Color(0xffFFFFFF)], 
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: vishingThreats.length,
            itemBuilder: (context, index) {
              String threatNumber = vishingThreats[index];
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[600],
                    child: const Icon(Icons.dangerous_sharp)
                  ),
                  title: Text(threatNumber),
                  subtitle: const Text('Potential vishing threat'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
