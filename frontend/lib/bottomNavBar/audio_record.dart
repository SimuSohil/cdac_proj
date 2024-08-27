import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioRecordScreen extends StatefulWidget {
  const AudioRecordScreen({super.key});

  @override
  State<AudioRecordScreen> createState() => _AudioRecordScreenState();
}

class _AudioRecordScreenState extends State<AudioRecordScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  String? _filePath;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _requestPermission();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _requestPermission() async {
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    PermissionStatus audioStorageStatus = await Permission.storage.request();

    if (Platform.isAndroid && await Permission.manageExternalStorage.isDenied) {
      audioStorageStatus = await Permission.manageExternalStorage.request();
    }

    if (microphoneStatus.isGranted && audioStorageStatus.isGranted) {
      log('Microphone and Storage permissions granted');
    } else {
      log('Microphone and/or storage permission denied');
    }
  }

  Future<void> _startRecording() async {
    if (_isRecorderInitialized) {
      Directory appDir = await getApplicationDocumentsDirectory(); // App-specific directory
      String audioDir = '${appDir.path}/audio_recordings';
      Directory(audioDir).createSync(recursive: true);
      _filePath = '$audioDir/audio_recording_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.aacADTS, // You can choose different codecs
      );
      setState(() {
        _isRecording = true;
        _statusMessage = 'Recording started...';
      });
    } else {
      log('Recorder is not initialized');
      setState(() {
        _statusMessage = 'Recorder is not initialized';
      });
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
      _statusMessage = 'Recording stopped. File saved at: $_filePath';
    });
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? null : _startRecording,
              child: const Text('Start Recording'),
            ),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : null,
              child: const Text('Stop Recording'),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
