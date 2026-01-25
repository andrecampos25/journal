import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecretService {
  static const String _boxName = 'secrets';
  static const String _geminiKey = 'gemini_api_key';

  Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  Future<void> saveGeminiKey(String key) async {
    final box = Hive.box(_boxName);
    await box.put(_geminiKey, key);
  }

  Future<String?> getGeminiKey() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    return box.get(_geminiKey) as String?;
  }

  Future<void> deleteGeminiKey() async {
    final box = Hive.box(_boxName);
    await box.delete(_geminiKey);
  }
}

final secretServiceProvider = Provider<SecretService>((ref) {
  return SecretService();
});
