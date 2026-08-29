import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = const String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'YOUR_API_KEY_HERE');
  
  // Test 1: List Models
  final response1 = await http.get(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
  );
  print('List Models Status: ${response1.statusCode}');
  print('List Models Body: ${response1.body}');
}
