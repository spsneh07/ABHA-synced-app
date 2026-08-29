import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  /// Saves a file to local application documents directory and returns the local file path
  Future<String?> uploadImage(File file, String userId) async {
    try {
      // Get the persistent local documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      
      // Create a specific folder for medical records if it doesn't exist
      final Directory recordsDir = Directory('${appDocDir.path}/medical_records/$userId');
      if (!await recordsDir.exists()) {
        await recordsDir.create(recursive: true);
      }
      
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = p.join(recordsDir.path, fileName);
      
      // Copy the file from the temporary cache directory to the persistent directory
      final File localImage = await file.copy(localPath);
      
      print('DEBUG: Successfully saved image locally to: ${localImage.path}');
      
      // Return the absolute local path with file:// schema so the UI knows it's a local file
      return 'file://${localImage.path}';
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  /// Deletes a file from local storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.startsWith('file://')) {
        final File file = File(imageUrl.replaceFirst('file://', ''));
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error deleting local image: $e');
    }
  }
}
