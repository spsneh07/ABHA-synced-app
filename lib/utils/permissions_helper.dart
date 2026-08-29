import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionsHelper {
  /// Requests camera permission and returns true if granted.
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true; // Bypass on Web
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Checks if camera permission is granted without requesting it.
  static Future<bool> hasCameraPermission() async {
    if (kIsWeb) return true; // Bypass on Web
    return await Permission.camera.isGranted;
  }
}
