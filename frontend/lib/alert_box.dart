import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AlertBoxSection extends StatefulWidget {
  const AlertBoxSection({super.key});

  @override
  State<AlertBoxSection> createState() => _AlertBoxSectionState();
}

class _AlertBoxSectionState extends State<AlertBoxSection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: 300,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Scam Alert!',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This number is flagged as a scam.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Action for 'End Call'
                  // You can implement functionality here
                },
                child: const Text('End Call'),
              ),
              ElevatedButton(
                onPressed: () {
                log('Try to close');
                FlutterOverlayWindow.closeOverlay()
                    .then((value) => log('STOPPED: alue: $value'));
              },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}