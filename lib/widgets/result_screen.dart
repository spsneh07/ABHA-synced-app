import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result.dart';

class ResultScreen extends StatelessWidget {
  final ScanResult scanResult;
  final VoidCallback onSave;

  const ResultScreen({
    Key? key,
    required this.scanResult,
    required this.onSave,
  }) : super(key: key);

  void _copyText(BuildContext context) {
    if (scanResult.extractedText != null && scanResult.extractedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: scanResult.extractedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard')),
      );
    }
  }

  void _shareText() {
    if (scanResult.extractedText != null && scanResult.extractedText!.isNotEmpty) {
      Share.share(scanResult.extractedText!);
    }
  }

  Widget _buildImage(File imageFile, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        kIsWeb 
          ? Image.network(
              imageFile.path, 
              height: 250, 
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            )
          : Image.file(
              imageFile, 
              height: 250, 
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (scanResult.capturedImage != null)
              _buildImage(scanResult.capturedImage!, 'Original Image'),
            
            if (scanResult.enhancedImage != null && scanResult.enhancedImage!.path != scanResult.capturedImage?.path)
              _buildImage(scanResult.enhancedImage!, 'Enhanced Image'),
            
            const Divider(height: 32, thickness: 1),
            
            const Text('Extracted Text', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: SelectableText(
                scanResult.extractedText?.isNotEmpty == true
                    ? scanResult.extractedText!
                    : 'No text extracted.',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyText(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareText,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Text'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
