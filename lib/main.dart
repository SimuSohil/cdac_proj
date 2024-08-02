import 'package:cdac_design/home_screen.dart';
import 'package:flutter/material.dart';
import 'phone_state_background_handler.dart';

void main(){
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState(){
    super.initState();
    _initializePhoneStateBackground();
  }

  Future<void> _initializePhoneStateBackground() async {
    await PhoneStateBackgroundHandler.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti-Vishing Application',
      theme: ThemeData(),
      home: const HomeScreen(),
    );
  }
}