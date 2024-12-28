import 'package:groq_sdk/groq_sdk.dart';
import 'package:groq_sdk/models/groq_chat.dart';

class ChatService {
  // Hardcoded API key
  static const String _apiKey = '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';

  final Groq groq = Groq(_apiKey);
  GroqChat? _chat;
  GroqChat? _chatVision;

  String systemPrompt = "You are a highly intelligent and friendly AI assistant. Your primary task is to provide thoughtful, helpful, and accurate responses to any message the user sends.";
  final String defaultPrompt = "You are a highly intelligent and friendly AI assistant. Your primary task is to provide thoughtful, helpful, and accurate responses to any message the user sends.";
  String selectedLanguage = "English";

  final String tagalogPrompt =
      "Use a natural, conversational tone that reflects how locals in the Philippines typically speak. Avoid deep or overly formal Tagalog words unless absolutely necessary.";

  Future<void> initialize() async {
    if (await groq.canUseModel(GroqModels.llama_33_70b_versatile)) {
      _chat = groq.startNewChat(GroqModels.llama_33_70b_versatile);
    }

    if (await groq.canUseModel(GroqModels.llama_32_90b_vision_preview)) {
      _chatVision = groq.startNewChat(GroqModels.llama_32_90b_vision_preview);
    }
  }

  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      throw Exception("Chat model is not initialized.");
    }

    final (response, _) = await _chat!.sendMessage(
      systemPrompt: systemPrompt,
      message,
    );
    return response.choices.first.message;
  }

  Future<String> sendMessageWithImage(String message, String imageUri) async {
    if (_chatVision == null) {
      throw Exception("Chat vision model is not initialized.");
    }

    final (response, _) = await _chatVision!.sendMessageWithVision(
      message + (selectedLanguage == "Tagalog" ? " $tagalogPrompt" : ""),
      imageUri
    );
    return response.choices.first.message;
  }

  Future transcibeAudio(String? _filePath) async {
    if(_filePath != null && _filePath.isNotEmpty) {
      try {
        final (transcriptionResult, rateLimitInformation) = await groq.transcribeAudio(
            audioFileUrl: _filePath,
            modelId: GroqModels.whisper_large_v2_turbo
        );
        print("TRANSCRIBED TEXT: ${transcriptionResult.text}"); // The transcribed text
      } on GroqException catch (e) {
        print('Error transcribing audio: $e');
      }
    }
  }

  Future<void> updateSettings({required String language, required String prompt}) async {
    selectedLanguage = language;
    systemPrompt = selectedLanguage == "Tagalog" ? "$prompt $tagalogPrompt" : prompt;
  }

  Future<int> getRemainingRequests() async {
    return _chat?.rateLimitInfo?.remainingRequestsToday ?? 0;
  }

  Future<int> getRemainingTokens() async {
    return _chat?.rateLimitInfo?.remainingTokensThisMinute ?? 0;
  }

  Future<void> dispose() async {
    _chat?.dispose();
    _chatVision?.dispose();
  }
}