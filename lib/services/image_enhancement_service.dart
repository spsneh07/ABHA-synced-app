import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageEnhancementService {
  /// Enhances the provided image by applying basic brightness/contrast adjustments
  /// and saving it to a new temporary file.
  static Future<File?> enhanceImage(File originalImage) async {
    try {
      final bytes = await originalImage.readAsBytes();
      // Decode image
      img.Image? decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      // Simple enhancement: adjust contrast and brightness slightly
      // to make text stand out more against the background.
      img.Image enhanced = img.adjustColor(decodedImage, contrast: 1.2, brightness: 1.1);

      // We can also apply a grayscale conversion if we want purely text,
      // but let's stick to color enhancement by default for medical records 
      // (sometimes colors matter for stamps/signatures).
      // If grayscale is preferred:
      // enhanced = img.grayscale(enhanced);

      // Encode back to JPEG
      final Uint8List enhancedBytes = img.encodeJpg(enhanced, quality: 90);

      // Save to a new temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(enhancedBytes);

      return tempFile;
    } catch (e) {
      print('Error enhancing image: $e');
      return null;
    }
  }
}
