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
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update found! Downloading...')));
           tryUpdate(apkUrl, context);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App is up to date.')));
        }
      } else {
        throw Exception('Failed to fetch release info');
      }
    } catch (e) {
      print('Update check failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update check failed: $e')));
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
      OtaUpdate().execute(url).listen(
        (OtaEvent event) {
            print('OTA Status: ${event.status}, Value: ${event.value}');
            // Optional: Update progress UI here if possible
        },
      );
    } catch (e) {
       print('OTA Error: $e');
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTA Error: $e')));
    }
  }
}
