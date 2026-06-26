import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _recordingPath;

  // Request microphone permission (native only)
  Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Check if permission is granted (native only)
  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // On web the browser handles mic permission natively when recording starts.
      // permission_handler is not supported on web and always returns denied.
      if (!kIsWeb) {
        if (!await hasPermission()) {
          final granted = await requestPermission();
          if (!granted) return false;
        }
      }

      if (kIsWeb) {
        // Web: record to memory (no file path needed)
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = '${directory.path}/expense_$timestamp.m4a';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (_) {
      return null;
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      // Temp file is intentionally left; OS will clean up app documents dir.
    } catch (_) {}
  }

  // Check if currently recording
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  // Dispose recorder
  void dispose() {
    _recorder.dispose();
  }
}
