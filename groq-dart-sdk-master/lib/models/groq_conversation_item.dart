import '../models/groq_message.dart';
import '../models/groq_response.dart';
import '../models/groq_usage.dart';

class GroqConversationItem {
  final String _model;
  final GroqMessage _request;
  GroqResponse? response;
  GroqUsage? usage;

  GroqConversationItem(this._model, this._request);

  String get model => _model;

  GroqMessage get request => _request;
}
