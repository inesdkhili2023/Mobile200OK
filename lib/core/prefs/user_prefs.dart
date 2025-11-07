import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const _kCity = 'pref_city';
  static const _kReminders = 'pref_reminders';

  Future<void> setCity(String city) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCity, city);
  }
  Future<String?> getCity() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kCity);
  }

  Future<void> setReminders(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kReminders, enabled);
  }
  Future<bool> getReminders() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kReminders) ?? true;
  }
}
