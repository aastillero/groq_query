import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  VoiceService() {
    _initializeTts();
  }

  void _initializeTts() {
    _flutterTts.setLanguage("en-US"); // Default language
    _flutterTts.setSpeechRate(0.5); // Set speech rate
    _flutterTts.setVolume(1.0); // Set volume
    _flutterTts.setPitch(1.0); // Set pitch
  }

  /// Speaks the given [text].
  Future<void> speak(String text) async {
    if (text.isEmpty) {
      throw Exception("Text is empty. Cannot convert to speech.");
    }

    await _flutterTts.speak(text);
  }

  /// Stops any ongoing speech.
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Changes the language for text-to-speech.
  Future<void> setLanguage(String languageCode) async {
    final languages = await _flutterTts.getLanguages;
    if (languages.contains(languageCode)) {
      await _flutterTts.setLanguage(languageCode);
    } else {
      throw Exception("Language $languageCode not supported.");
    }
  }

  Future<void> getLanguages() async {
    final languages = await _flutterTts.getLanguages;
    print("LANGUAGES: $languages");
  }

  /// Starts listening for speech and returns the transcribed text.
  Future<String?> startListening() async {
    if (!_speechToText.isAvailable) {
      throw Exception("Speech recognition is not available on this device.");
    }

    if (!_isListening) {
      _isListening = true;
      final isInitialized = await _speechToText.initialize();
      if (!isInitialized) {
        throw Exception("Failed to initialize speech recognition.");
      }

      await _speechToText.listen(
        onResult: (result) {
          // You can handle live transcription here
          print("Partial result: ${result.recognizedWords}");
        },
      );
    }
    return null; // Return result in onResult instead
  }

  /// Stops listening and returns the final transcription.
  Future<String?> stopListening() async {
    if (_isListening) {
      final transcription = _speechToText.lastRecognizedWords;
      await _speechToText.stop();
      _isListening = false;
      return transcription;
    }
    return null;
  }

  /// Disposes the TTS and Speech-to-Text instances.
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
  }
}