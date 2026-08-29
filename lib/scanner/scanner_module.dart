import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScannerModule {
  final ImagePicker _imagePicker = ImagePicker();
  DocumentScanner? _documentScanner;

  ScannerModule() {
    if (!kIsWeb) {
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          mode: ScannerMode.full,
          pageLimit: 1,
          isGalleryImport: true,
        ),
      );
    }
  }

  Future<File?> scanDocument() async {
    try {
      if (kIsWeb) {
        // Fallback for Web: Use standard image picker
        final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          return File(image.path);
        }
        return null;
      } else {
        // Native ML Kit Scanner
        if (_documentScanner == null) return null;
        final DocumentScanningResult result = await _documentScanner!.scanDocument();
        if (result.images?.isNotEmpty == true) {
          return File(result.images!.first);
        }
        return null;
      }
    } catch (e) {
      print('Error during scanning: $e');
      return null;
    }
  }

  void dispose() {
    _documentScanner?.close();
  }
}
