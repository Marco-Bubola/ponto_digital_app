import 'package:shared_preferences/shared_preferences.dart';

class AuthFlagService {
  static const String _key = 'has_logged_in_once';

  static Future<void> setLoggedInOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<bool> hasLoggedInOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }
}
