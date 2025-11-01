import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl =
      'https://us-central1-slideme-87da5.cloudfunctions.net/chatbot';

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "No response";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
