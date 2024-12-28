import 'dart:convert';

import '../extensions/groq_json_extensions.dart';
import '../models/groq_chat.dart';
import '../models/groq_conversation_item.dart';
import '../models/groq_exceptions.dart';
import '../models/groq_llm_model.dart';
import '../models/groq_message.dart';
import '../models/groq_rate_limit_information.dart';
import '../models/groq_response.dart';
import '../models/groq_audio_response.dart';
import '../models/groq_usage.dart';
import '../utils/auth_http.dart';
import '../utils/groq_parser.dart';
import 'package:http/http.dart' as http;

class GroqApi {
  static const String _chatCompletionUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _getModelBaseUrl =
      'https://api.groq.com/openai/v1/models';
  static const String _getAudioTranscriptionUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _getAudioTranslationUrl =
      'https://api.groq.com/openai/v1/audio/translations';

  ///Returns the model metadata from groq with the given model id
  static Future<GroqLLMModel> getModel(String modelId, String apiKey) async {
    final response =
        await AuthHttp.get(url: '$_getModelBaseUrl/$modelId', apiKey: apiKey);
    if (response.statusCode == 200) {
      return GroqParser.llmModelFromJson(
          json.decode(utf8.decode(response.bodyBytes, allowMalformed: true)));
    } else {
      throw GroqException.fromResponse(response);
    }
  }

  ///Returns a list of all model metadatas available in Groq
  static Future<List<GroqLLMModel>> listModels(String apiKey) async {
    final response = await AuthHttp.get(url: _getModelBaseUrl, apiKey: apiKey);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData =
          json.decode(utf8.decode(response.bodyBytes, allowMalformed: true));
      final List<dynamic> jsonList = jsonData['data'] as List<dynamic>;
      return jsonList.map((json) => GroqParser.llmModelFromJson(json)).toList();
    } else {
      throw GroqException.fromResponse(response);
    }
  }

  ///Returns a new chat instance with the given model id
  static Future<(GroqResponse, GroqUsage, GroqRateLimitInformation)>
      getNewChatCompletion({
    required String apiKey,
    required GroqMessage prompt,
    required GroqChat chat,
    required bool expectJSON,
    String? img,
    GroqMessage? systemPrompt,
  }) async {
    final Map<String, dynamic> jsonMap = {};
    List<Map<String, dynamic>> messages = [];
    List<GroqConversationItem> allMessages = chat.allMessages;
    if (chat.allMessages.length > chat.settings.maxConversationalMemoryLength) {
      allMessages.removeRange(
          0, allMessages.length - chat.settings.maxConversationalMemoryLength);
    }
    // in context memory
    for (final message in allMessages) {
      messages.add(message.request.toJson());
      messages.add(message.response!.choices.first.messageData.toJson());
    }

    if(img != null) {
      messages.add({
        "role": "user",
        "content": [
          {"type": "text", "text": "${prompt.content}"},
          {
            "type": "image_url",
            "image_url": {
              "url": "$img",
            },
          },
        ],
      });
    } else {
      if(systemPrompt != null) {
        messages.add(systemPrompt.toJson());
      }
      messages.add(prompt.toJson());
    }
    jsonMap['messages'] = messages;
    jsonMap['model'] = chat.model;
    if (expectJSON) {
      jsonMap['response_format'] = {"type": "json_object"};
    }
    jsonMap.addAll(chat.settings.toJson());
    print("jsonBody: $jsonMap");
    final response = await AuthHttp.post(
        url: _chatCompletionUrl, apiKey: apiKey, body: jsonMap);
    print("resp: ${response.body}");
    //Rate Limit information
    final rateLimitInfo =
        GroqParser.rateLimitInformationFromHeaders(response.headers);
    if (response.statusCode < 300) {
      final Map<String, dynamic> jsonData =
          json.decode(utf8.decode(response.bodyBytes, allowMalformed: true));
      final GroqResponse groqResponse =
          GroqParser.groqResponseFromJson(jsonData);
      final GroqUsage groqUsage =
          GroqParser.groqUsageFromChatJson(jsonData["usage"]);
      return (groqResponse, groqUsage, rateLimitInfo);
    } else if (response.statusCode == 429) {
      throw GroqRateLimitException(
        retryAfter: Duration(
          seconds: int.tryParse(response.headers['retry-after'] ?? '0') ?? 0,
        ),
      );
    } else {
      throw GroqException.fromResponse(response);
    }
  }

  ///transcribes the audio file at the given path using the model with the given model id
  static Future<(GroqAudioResponse, GroqRateLimitInformation)> transcribeAudio({
    required String apiKey,
    required String filePath,
    required String modelId,
    required Map<String, String> optionalParameters,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse(_getAudioTranscriptionUrl));

    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['model'] = modelId;

    // Add optional fields from the map
    optionalParameters.forEach((key, value) {
      request.fields[key] = value;
    });

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final jsonBody = json.decode(responseBody);
    if (response.statusCode == 200) {
      final audioResponse = GroqParser.audioResponseFromJson(jsonBody);
      print(jsonBody);
      // final usage =
      //     GroqParser.groqUsageFromAudioJson(jsonBody['x_groq']['usage']);
      final rateLimitInfo =
          GroqParser.rateLimitInformationFromHeaders(response.headers);
      return (audioResponse, rateLimitInfo);
    } else {
      throw GroqException(
          statusCode: response.statusCode, error: GroqError.fromJson(jsonBody));
    }
  }

  ///Translates the audio file at the given file path to text
  static Future<(GroqAudioResponse, GroqRateLimitInformation)> translateAudio({
    required String apiKey,
    required String filePath,
    required String modelId,
    required double temperature,
  }) async {
    var request =
        http.MultipartRequest('POST', Uri.parse(_getAudioTranslationUrl));

    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Content-Type'] = 'multipart/form-data';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['model'] = modelId;
    request.fields['temperature'] = temperature.toString();

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final jsonBody = json.decode(responseBody);
    if (response.statusCode == 200) {
      final audioResponse = GroqParser.audioResponseFromJson(jsonBody);
      final rateLimitInfo =
          GroqParser.rateLimitInformationFromHeaders(response.headers);
      return (audioResponse, rateLimitInfo);
    } else {
      throw GroqException(
          statusCode: response.statusCode, error: GroqError.fromJson(jsonBody));
    }
  }
}
