import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class ErrorDialog {
  /// Displays a friendly error dialog based on the ScanStatus
  static void show(BuildContext context, ScanResult result) {
    String title = 'Error';
    String message = result.message ?? 'An unknown error occurred.';

    switch (result.status) {
      case ScanStatus.permissionDenied:
        title = 'Permission Denied';
        message = 'Please grant camera and storage permissions in your device settings to use the scanner.';
        break;
      case ScanStatus.noDocumentDetected:
        title = 'No Document Detected';
        message = 'We could not detect a document. Please try again with better lighting and contrast.';
        break;
      case ScanStatus.ocrFailure:
        title = 'Text Extraction Failed';
        message = 'We could not extract any readable text from the image. Please ensure the document is clear.';
        break;
      case ScanStatus.lowQualityImage:
        title = 'Low Quality Image';
        message = 'The image quality is too low for accurate text extraction. Please scan again.';
        break;
      case ScanStatus.cancelled:
        // Generally we don't show an error for cancellation, but leaving here for completeness
        title = 'Cancelled';
        message = 'Scanning operation was cancelled.';
        break;
      case ScanStatus.error:
      case ScanStatus.success:
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
