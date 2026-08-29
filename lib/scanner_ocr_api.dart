import 'dart:io';
import 'package:flutter/material.dart';
import 'models/scan_result.dart';
import 'scanner/scanner_module.dart';
import 'ocr/ocr_module.dart';
import 'services/image_enhancement_service.dart';
import 'utils/permissions_helper.dart';

export 'models/scan_result.dart';
export 'widgets/result_screen.dart';
export 'widgets/error_dialog.dart';

class ScannerOcrApi {
  final ScannerModule _scannerModule = ScannerModule();
  final OcrModule _ocrModule = OcrModule();

  /// Main entry point to scan a document and extract text.
  Future<ScanResult> scanDocument() async {
    // 1. Permissions Check
    bool hasPermission = await PermissionsHelper.requestCameraPermission();
    if (!hasPermission) {
      return ScanResult.failure(ScanStatus.permissionDenied);
    }

    // 2. Scan Document
    final File? capturedImage = await _scannerModule.scanDocument();
    if (capturedImage == null) {
      // User cancelled or no document detected
      return ScanResult.failure(ScanStatus.cancelled, message: 'Scanning cancelled.');
    }

    // 3. Image Enhancement
    final File? enhancedImage = await ImageEnhancementService.enhanceImage(capturedImage);
    final File finalImage = enhancedImage ?? capturedImage;

    // 4. OCR Text Extraction
    final String? extractedText = await _ocrModule.extractText(finalImage);
    if (extractedText == null || extractedText.trim().isEmpty) {
      return ScanResult.failure(
        ScanStatus.ocrFailure, 
        message: 'Could not extract text from the document.',
      );
    }

    // 5. Return success result
    return ScanResult.success(
      capturedImage: capturedImage,
      enhancedImage: finalImage,
      extractedText: extractedText,
      confidence: 1.0, 
    );
  }

  /// Disposes of the underlying services
  void dispose() {
    _scannerModule.dispose();
    _ocrModule.dispose();
  }
}
