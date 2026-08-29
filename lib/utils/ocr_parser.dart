import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_record.dart';

class OcrParser {
  // Provided by user
  // To use the Gemini API, pass the key during build/run:
  // flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Analyzes the raw OCR text using Gemini and returns a partially populated MedicalRecord.
  /// Note: The caller must still fill in id, userId, imageUrl, createdAt, and extractedText.
  static Future<MedicalRecord> analyzeMedicalText(String rawText, String tempId, String tempUserId, String tempImageUrl) async {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE' || _geminiApiKey.isEmpty) {
      // Fallback to basic regex if API key is not set
      return _buildFallback(rawText, tempId, tempUserId, tempImageUrl);
    }

    try {
      final prompt = '''
Analyze the following raw OCR text extracted from a medical document (like a prescription or lab report).
Extract the following information and return it EXACTLY as a valid JSON object without any markdown formatting, code blocks, or extra text.

Required JSON format:
{
  "hospitalName": "Name of the hospital, clinic, or doctor. If not found, output null",
  "patientName": "Name of the patient. If not found, output null",
  "patientAge": "Age of patient. If not found, output null",
  "patientGender": "Gender of patient (Male, Female, etc). If not found, output null",
  "recordDate": "Date of the record. If not found, output null",
  "diagnosis": "The main diagnosis, disease, or symptoms. If not found, output null",
  "medicines": ["Medicine 1 with dosage", "Medicine 2 with dosage"] (empty array if none found)
}

OCR Text:
"""
$rawText
"""
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        print('Gemini HTTP Error: ${response.statusCode} - ${response.body}');
        return _buildFallback(rawText, tempId, tempUserId, tempImageUrl);
      }

      final jsonResponse = jsonDecode(response.body);
      final String responseText = jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      
      // Clean up markdown block if Gemini accidentally wraps it
      final cleanedText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> data = jsonDecode(cleanedText);

      List<String> medicinesList = [];
      if (data['medicines'] != null && data['medicines'] is List) {
        medicinesList = List<String>.from(data['medicines']);
      }

      return MedicalRecord(
        id: tempId,
        userId: tempUserId,
        title: data['hospitalName']?.toString().isNotEmpty == true ? data['hospitalName'] : 'Medical Record',
        extractedText: rawText,
        imageUrl: tempImageUrl,
        createdAt: DateTime.now(),
        patientName: data['patientName'],
        hospitalName: data['hospitalName'],
        medicines: medicinesList,
        recordDate: data['recordDate'],
        diagnosis: data['diagnosis'],
        patientAge: data['patientAge'],
        patientGender: data['patientGender'],
      );
    } catch (e) {
      print('Gemini Parsing Error: $e');
      return _buildFallback(rawText, tempId, tempUserId, tempImageUrl);
    }
  }

  static MedicalRecord _buildFallback(String rawText, String tempId, String tempUserId, String tempImageUrl) {
    return MedicalRecord(
      id: tempId,
      userId: tempUserId,
      title: _extractHospitalNameBasic(rawText) ?? 'Medical Record',
      extractedText: rawText,
      imageUrl: tempImageUrl,
      createdAt: DateTime.now(),
      patientName: _extractPatientNameBasic(rawText),
      hospitalName: _extractHospitalNameBasic(rawText),
      medicines: _extractMedicinesBasic(rawText),
    );
  }

  // --- Basic Fallbacks (used if API fails or key is missing) ---

  static List<String> _extractMedicinesBasic(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final List<String> medicines = [];

    final medicinePrefixes = RegExp(r'\b(Tab\.?|Tablet|Cap\.?|Capsule|Syp\.?|Syr\.?|Syrup|Inj\.?|Injection|Oint\.?|Ointment|Drops)\b', caseSensitive: false);
    final dosagePatterns = RegExp(r'\b(\d-\d-\d|\d-\d|bd|od|tds|tid|sos|stat)\b', caseSensitive: false);
    final weakDosagePatterns = RegExp(r'\b(mg|ml)\b', caseSensitive: false);

    for (var line in lines) {
      if (medicinePrefixes.hasMatch(line) || dosagePatterns.hasMatch(line) || weakDosagePatterns.hasMatch(line)) {
        if (line.length > 3 && line.length < 100) {
           final cleanLine = line.replaceAll(RegExp(r'^[^a-zA-Z0-9]+'), '').trim();
           
           if (cleanLine.isNotEmpty && !cleanLine.toLowerCase().startsWith('date') && !cleanLine.toLowerCase().startsWith('age')) {
             
             final hasPrefix = medicinePrefixes.hasMatch(cleanLine);
             final hasStrongDosage = dosagePatterns.hasMatch(cleanLine);

             if (!hasPrefix && hasStrongDosage && medicines.isNotEmpty && cleanLine.length < 25) {
                 final lastIndex = medicines.length - 1;
                 medicines[lastIndex] = '${medicines[lastIndex]}   ➔   $cleanLine';
             } else {
                 medicines.add(cleanLine);
             }
           }
        }
      }
    }
    return medicines;
  }

  static String? _extractPatientNameBasic(String text) {
    final RegExp nameRegex = RegExp(r'(?:Name|Patient\s*Name|Pt\.?\s*Name|To)[\s:-]+([A-Za-z\s]{3,30})(?=\n|$)', caseSensitive: false);
    final match = nameRegex.firstMatch(text);
    if (match != null && match.groupCount >= 1) {
      final name = match.group(1)?.trim();
      if (name != null && !name.toLowerCase().contains(RegExp(r'\b(age|sex|date|time)\b'))) {
        return name;
      }
    }
    return null;
  }

  static String? _extractHospitalNameBasic(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return null;
    final hospitalKeywords = RegExp(r'\b(hospital|clinic|care|health|diagnostics|lab|laboratory|institute|centre|center|pathology|nursing)\b', caseSensitive: false);
    for (var line in lines) {
      if (hospitalKeywords.hasMatch(line) && line.length > 5 && line.length < 60) {
        return line.replaceAll(RegExp(r'^[^a-zA-Z]+'), '').trim();
      }
    }
    for (var i = 0; i < (lines.length > 3 ? 3 : lines.length); i++) {
      if (lines[i].toLowerCase().startsWith('dr.') || lines[i].toLowerCase().startsWith('dr ')) {
        return lines[i].replaceAll(RegExp(r'^[^a-zA-Z]+'), '').trim();
      }
    }
    if (lines[0].length > 5 && lines[0].length < 40) {
      final firstLine = lines[0].replaceAll(RegExp(r'^[^a-zA-Z]+'), '').trim();
      if (firstLine.isNotEmpty) return firstLine;
    }
    return null;
  }
}
