import 'dart:io';

/// Enum representing the status of the scanning operation.
enum ScanStatus {
  success,
  permissionDenied,
  noDocumentDetected,
  ocrFailure,
  lowQualityImage,
  cancelled,
  error,
}

/// Represents the result of a document scan operation.
class ScanResult {
  /// The original captured image.
  final File? capturedImage;

  /// The processed/enhanced document image.
  final File? enhancedImage;

  /// The text extracted via OCR.
  final String? extractedText;

  /// Confidence score of the OCR (if available).
  final double? confidence;

  /// The final status of the operation.
  final ScanStatus status;

  /// A descriptive message, usually populated on error.
  final String? message;

  ScanResult({
    this.capturedImage,
    this.enhancedImage,
    this.extractedText,
    this.confidence,
    required this.status,
    this.message,
  });

  /// Factory constructor for successful scans.
  factory ScanResult.success({
    required File capturedImage,
    required File enhancedImage,
    required String extractedText,
    double? confidence,
  }) {
    return ScanResult(
      capturedImage: capturedImage,
      enhancedImage: enhancedImage,
      extractedText: extractedText,
      confidence: confidence,
      status: ScanStatus.success,
    );
  }

  /// Factory constructor for failures.
  factory ScanResult.failure(ScanStatus status, {String? message}) {
    return ScanResult(
      status: status,
      message: message,
    );
  }
}
