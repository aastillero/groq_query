import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for ChangeNotifier
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioService extends ChangeNotifier {
  final ValueNotifier<bool> isRecordingNotifier = ValueNotifier(false);
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isMonitoring = false;
  bool _isRecording = false;
  bool _isPlaying = false;

  String? _filePath;
  StreamSubscription? _recorderSubscription;

  final double _silenceThreshold = -45.0; // Decibel threshold for silence
  final double _decibelThreshold = 40.0;
  final Duration _silenceDuration = const Duration(seconds: 1); // Silence timeout
  Timer? _silenceTimer;

  bool get isMonitoring => _isMonitoring;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  Future<void> initialize() async {
    await Permission.microphone.request();

    if (!await Permission.microphone.isGranted) {
      throw Exception("Microphone permission not granted.");
    }

    await _recorder.openRecorder();
    _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
    await _player.openPlayer();
  }

  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    notifyListeners();

    await _recorder.startRecorder(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );

    //print('Recorder started, subscribing to onProgress...');
    _recorderSubscription = _recorder.onProgress!.listen((event) {
      //print('Received onProgress event');
      double currentDb = event.decibels ?? 0.0;
      //print("currentDB: $currentDb   isRec: $_isRecording");
      if (_isRecording) {
        if (currentDb < _decibelThreshold) {
          //print("start silence");
          _startSilenceTimer();
        } else {
          //print("cancel silence");
          _cancelSilenceTimer();
        }
      } else {
        //if (currentDb > _decibelThreshold) {
          _startRecording();
        //}
      }
    });

    //print('Starting recorder...');
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _cancelSilenceTimer();

    if (_isRecording) {
      await _stopRecording();
    }

    await _recorder.stopRecorder();
    _recorderSubscription?.cancel();
    _recorderSubscription = null;

    _isMonitoring = false;
    notifyListeners();
  }

  Future<void> _startRecording() async {
    print("_startRecording method=================================================");
    //if (_isRecording) return;

    await _recorder.stopRecorder();
    String dir = (await getApplicationDocumentsDirectory()).path;
    _filePath = "$dir/audio_recording.mp4";

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.aacMP4,
    );

    _isRecording = true;
    isRecordingNotifier.value = true;
    notifyListeners();
  }

  Future<void> _stopRecording() async {
    print("_stopRecording method=================================================");
    //if (!_isRecording) return;

    await _recorder.stopRecorder();

    if (_isMonitoring) {
      await _recorder.startRecorder(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100,
      );
    }

    _isRecording = false;
    //await playRecording();
    isRecordingNotifier.value = false;
    notifyListeners();
    //stopMonitoring();
  }

  Future<void> playRecording() async {
    if (_isPlaying || _filePath == null || !File(_filePath!).existsSync()) return;

    await _player.startPlayer(
      fromURI: _filePath,
      codec: Codec.aacADTS,
      whenFinished: () {
        _isPlaying = false;
        notifyListeners();
      },
    );

    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stopPlaying() async {
    if (!_isPlaying) return;

    await _player.stopPlayer();
    _isPlaying = false;
    notifyListeners();
  }

  String? getRecordedFilePath() => _filePath;

  // Silence Detection Logic
  void _startSilenceTimer() {
    if (_silenceTimer != null && _silenceTimer!.isActive) {
      // Timer is already running
      return;
    }

    _silenceTimer = Timer(_silenceDuration, () {
      _stopRecording();
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }
}