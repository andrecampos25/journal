import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

// Keys for Hive Boxes
const String kCacheBox = 'app_cache';
const String kQueueBox = 'mutation_queue';

class OfflineService {
  late Box _cacheBox;
  late Box _queueBox;
  final Uuid _uuid = const Uuid();

  // Initialize boxes
  Future<void> init() async {
    _cacheBox = await Hive.openBox(kCacheBox);
    _queueBox = await Hive.openBox(kQueueBox);
  }

  // Check connection status
  Future<bool> get isOnline async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) || 
           connectivityResult.contains(ConnectivityResult.wifi) ||
           connectivityResult.contains(ConnectivityResult.ethernet);
  }

  // --- Caching ---

  // Save data to cache
  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, jsonEncode(data));
  }

  // Get data from cache
  dynamic getCachedData(String key) {
    final String? jsonString = _cacheBox.get(key);
    if (jsonString != null) {
       return jsonDecode(jsonString);
    }
    return null;
  }

  // --- Mutation Queue ---

  // Queue a mutation to be synced later
  // type: 'create_habit', 'toggle_habit', 'create_task', etc.
  Future<void> queueMutation(String type, Map<String, dynamic> payload) async {
    final mutation = {
      'id': _uuid.v4(),
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _queueBox.add(mutation);
  }

  // Get current queue
  List<Map<String, dynamic>> getQueue() {
    return _queueBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Remove item from queue (after successful sync)
  Future<void> removeFromQueue(String id) async {
    final Map<dynamic, dynamic> map = _queueBox.toMap();
    final key = map.keys.firstWhere((k) => map[k]['id'] == id, orElse: () => null);
    if (key != null) {
      await _queueBox.delete(key);
    }
  }
  
  // Clear queue
  Future<void> clearQueue() async {
    await _queueBox.clear();
  }
}

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});
