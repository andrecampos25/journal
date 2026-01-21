import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtaService {
  // Check and update from a URL
  // In a real app, you'd fetch the latest version details from Supabase first.
  // Then compare package_info version with remote version.
  // If remote > local, trigger download.
  
  // Replace with your actual GitHub Raw URL
  static const String kUpdateUrl = 'https://raw.githubusercontent.com/andrecampos25/journal/main/release.json';

  Future<void> checkForUpdates() async {
    try {
      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      print('Current Version: $currentVersion');

      // 2. Fetch remote version info
      final response = await http.get(Uri.parse(kUpdateUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersion = data['version'];
        final apkUrl = data['apkUrl'];
        
        print('Remote Version: $remoteVersion');

        // 3. Compare
        if (_isVersionGreaterThan(remoteVersion, currentVersion)) {
           print('Update available! Downloading...');
           tryUpdate(apkUrl);
        } else {
           print('App is up to date.');
        }
      }
    } catch (e) {
      print('Update check failed: $e');
    }
  }

  bool _isVersionGreaterThan(String newVer, String currentVer) {
    // Very naive string compare for MVP.
    // Ideally split by dots and compare integers.
    return newVer != currentVer; 
  }

  Future<void> tryUpdate(String url) async {
    try {
      OtaUpdate().execute(url).listen(
        (OtaEvent event) {
            print('OTA Status: ${event.status}, Value: ${event.value}');
        },
      );
    } catch (e) {
       print('OTA Error: $e');
    }
  }
}
