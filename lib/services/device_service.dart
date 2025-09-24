import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class DeviceService {
  static const _keyDeviceId = 'ponto_device_id';

  static Future<String> _generateId() async {
    final rand = Random();
    final parts = List.generate(4, (_) => rand.nextInt(0x10000).toRadixString(16));
    return 'dev-${parts.join('-')}';
  }

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null) {
      id = await _generateId();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }
}

