import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrModule {
  TextRecognizer? _textRecognizer;

  OcrModule() {
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  Future<String?> extractText(File imageFile) async {
    try {
      if (kIsWeb) {
        // Web Fallback: Mock OCR text
        await Future.delayed(const Duration(seconds: 2));
        return "MOCK OCR TEXT FOR WEB\n\nPatient Name: John Doe\nHospital: General Hospital\nDate: 2026-06-27\n\nThis is a mocked OCR result because Google ML Kit does not support Flutter Web.";
      } else {
        if (_textRecognizer == null) return null;
        final inputImage = InputImage.fromFile(imageFile);
        final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
        return recognizedText.text;
      }
    } catch (e) {
      print('Error during OCR extraction: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
