import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final otaServiceProvider = Provider((ref) => OtaService());

class OtaService {
  // Replace with your actual GitHub Raw URL
  static const String kUpdateUrl = 'https://raw.githubusercontent.com/andrecampos25/journal/main/release.json';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking for updates...')));

      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint('Current Version: $currentVersion');

      // 2. Fetch remote version info with cache-breaker
      final cacheBreaker = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$kUpdateUrl?cb=$cacheBreaker'));
      
      if (!context.mounted) return;
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final remoteVersion = data['version'] as String;
        final apkUrl = data['apkUrl'] as String;
        
        debugPrint('OTA Check: Remote=$remoteVersion, Local=$currentVersion');

        // 3. Compare with better logging
        final isUpdateAvailable = _isVersionGreaterThan(remoteVersion, currentVersion);
        debugPrint('OTA Check: Is Update Available? $isUpdateAvailable');

        if (isUpdateAvailable) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Update found: v$remoteVersion. Downloading...'),
               backgroundColor: Colors.green,
             )
           );
           tryUpdate(apkUrl, context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date.')));
        }
      } else {
        throw Exception('Failed to fetch release info');
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update check failed: $e')));
    }
  }

  bool _isVersionGreaterThan(String newVer, String currentVer) {
    List<int> newParts = newVer.split('.').map(int.parse).toList();
    List<int> currentParts = currentVer.split('.').map(int.parse).toList();
    
    for (int i = 0; i < newParts.length; i++) {
      if (i >= currentParts.length) return true; // New has more parts: 1.0.1 > 1.0
      if (newParts[i] > currentParts[i]) return true;
      if (newParts[i] < currentParts[i]) return false;
    }
    return false; // Equal or smaller
  }

  Future<void> tryUpdate(String url, BuildContext context) async {
    try {
      OtaUpdate().execute(
        url, 
        destinationFilename: 'life_os_update.apk',
        androidProviderAuthority: 'com.lifeos.life_os.ota_update_provider',
      ).listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              // For simplicity, we just log progress, but could update a state provider
              debugPrint('OTA: Downloading ${event.value}%');
              break;
            case OtaStatus.INSTALLING:
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting installation...')));
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update already in progress.')));
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied to install updates.')));
              break;
            case OtaStatus.DOWNLOAD_ERROR:
            case OtaStatus.CHECKSUM_ERROR:
            case OtaStatus.INTERNAL_ERROR:
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: ${event.status}')));
              break;
            default:
              break;
          }
        },
      );
    } catch (e) {
       debugPrint('OTA Error: $e');
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTA Error: $e')));
    }
  }
}
