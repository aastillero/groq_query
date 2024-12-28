import '../models/groq_chat.dart';
import '../models/groq_conversation_item.dart';
import '../models/groq_message.dart';
import '../models/groq_response.dart';
import '../models/groq_usage.dart';
import '../utils/groq_parser.dart';

extension GroqChatSettingsExtension on GroqChatSettings {
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'max_tokens': maxTokens,
      'top_p': topP,
      // 'unknown': choicesCount,
      // 'stream': stream,
      'stop': stop,
    };
  }
}

extension GroqConversationItemExtension on GroqConversationItem {
  void setResponse(GroqResponse response, GroqUsage usage) {
    this.response = response;
    this.usage = usage;
  }

  void setResponseFromJson(Map<String, dynamic> json) {
    response = GroqParser.groqResponseFromJson(json);
    usage = GroqParser.groqUsageFromChatJson(json);
  }
}

extension GroqMessageExtension on GroqMessage {
  Map<String, dynamic> toJson() {
    final jsonMap = {
      'content': content,
      'role': GroqMessageRoleParser.toId(role),
    };
    if (username != null) {
      jsonMap['user'] = username!;
    }
    return jsonMap;
  }
}

extension GroqContentExtension on GroqContent {
  Map<String, dynamic> toJson() {
    final jsonMap = {
      'type': type,
    };
    if (text != null) {
      jsonMap['text'] = text!;
    }
    if (image_url != null) {
      jsonMap['image_url'] = image_url!;
    }
    return jsonMap;
  }

  String toJsonString() {
    final jsonMap = {
      'type': type,
    };
    if (text != null) {
      jsonMap['text'] = text!;
    }
    if (image_url != null) {
      jsonMap['image_url'] = image_url!;
    }
    return jsonMap.toString();
  }
}
