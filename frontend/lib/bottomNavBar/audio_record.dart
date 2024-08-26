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
  bool _isRecorderInitialized= false;

  @override
  void initState(){
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

    if(microphoneStatus.isGranted && audioStorageStatus.isGranted){
      log('Microphone and Storage permissions granted');
    }
    else {
      log('Microphone and/or storage permission denied');
    }
  }

  Future<void> _startRecording() async {
    if (_isRecorderInitialized) {
      // Get the list of external storage directories
      List<Directory>? musicDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
      if (musicDirs != null && musicDirs.isNotEmpty) {
        // Use the first directory in the list
        String musicPath = musicDirs[0].path; // Path to the Music folder
        // Create the Music directory if it doesn't exist
        Directory(musicPath).createSync(recursive: true);
        _filePath = '$musicPath/audio_recording_${DateTime.now().millisecondsSinceEpoch}.aac'; 
        await _recorder.startRecorder(
          toFile: _filePath,
          codec: Codec.aacADTS, // You can choose different codecs
        );
        setState(() {
          _isRecording = true;
        });
      } else {
        log('No music directory found');
      }
    } else {
      // Handle the case when the recorder is not initialized
      log('Recorder is not initialized');
    }
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

   @override
  void dispose() {
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
            if (_filePath != null) ...[
              const SizedBox(height: 20),
              Text('Recorded file: $_filePath'),
            ],
          ],
        ),
      ),
    );
  }
}