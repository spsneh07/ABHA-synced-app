import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AQ.Ab8RN6JvvYhPqZ3EYWQaZP9ZJ-iwLI3XCA5FmOmNajDlhLAUBQ';
  
  // Test 1: List Models
  final response1 = await http.get(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
  );
  print('List Models Status: ${response1.statusCode}');
  print('List Models Body: ${response1.body}');
}
