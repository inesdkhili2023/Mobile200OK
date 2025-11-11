import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
static SharedPreferences? _prefs;  
  // Initialize SharedPreferences once at app startup
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _keyUserName = 'user_name';
  static const String _keyUserPhone = 'user_phone';
  static const String _keySelectedWorkers = 'selected_workers';
  static const String _keyRecentSearches = 'recent_searches';
  static const String _keyNotifications = 'notifications';

  // User name methods
  static Future<void> setUserName(String name) async {
    await _prefs?.setString(_keyUserName, name);
  }

  static String? getUserName() {
    return _prefs?.getString(_keyUserName);
  }

  // User phone methods
  static Future<void> setUserPhone(String phone) async {
    await _prefs?.setString(_keyUserPhone, phone);
  }

  static String? getUserPhone() {
    return _prefs?.getString(_keyUserPhone);
  }

  // Selected workers methods - NOW SYNCHRONOUS
  static Future<void> addSelectedWorker(int workerId) async {
    List<String> workers = _prefs?.getStringList(_keySelectedWorkers) ?? [];
    if (!workers.contains(workerId.toString())) {
      workers.add(workerId.toString());
      await _prefs?.setStringList(_keySelectedWorkers, workers);
    }
  }

  static Future<void> removeSelectedWorker(int workerId) async {
    List<String> workers = _prefs?.getStringList(_keySelectedWorkers) ?? [];
    workers.remove(workerId.toString());
    await _prefs?.setStringList(_keySelectedWorkers, workers);
  }

  static List<int> getSelectedWorkers() {
    List<String> workers = _prefs?.getStringList(_keySelectedWorkers) ?? [];
    return workers.map((w) => int.parse(w)).toList();
  }

  static Future<void> clearSelectedWorkers() async {
    await _prefs?.remove(_keySelectedWorkers);
  }

  // Recent searches methods - NOW SYNCHRONOUS
  static Future<void> addRecentSearch(String search) async {
    List<String> searches = _prefs?.getStringList(_keyRecentSearches) ?? [];
    
    // Remove if already exists to avoid duplicates
    searches.remove(search);
    
    // Add to beginning
    searches.insert(0, search);
    
    // Keep only last 10 searches
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    
    await _prefs?.setStringList(_keyRecentSearches, searches);
  }

  static List<String> getRecentSearches() {
    return _prefs?.getStringList(_keyRecentSearches) ?? [];
  }

  static Future<void> clearRecentSearches() async {
    await _prefs?.remove(_keyRecentSearches);
  }

  // Notifications methods
  static Future<void> addNotification(String notification) async {
    List<String> notifications = _prefs?.getStringList(_keyNotifications) ?? [];
    
    // Add with timestamp
    String timestamped = '${DateTime.now().toIso8601String()}|||$notification';
    notifications.insert(0, timestamped);
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications = notifications.sublist(0, 50);
    }
    
    await _prefs?.setStringList(_keyNotifications, notifications);
  }

  static List<Map<String, String>> getNotifications() {
    List<String> notifications = _prefs?.getStringList(_keyNotifications) ?? [];
    return notifications.map((n) {
      final parts = n.split('|||');
      return {
        'timestamp': parts[0],
        'message': parts.length > 1 ? parts[1] : n,
      };
    }).toList();
  }

  static int getUnreadNotificationsCount() {
    return getNotifications().length;
  }

  static Future<void> clearNotifications() async {
    await _prefs?.remove(_keyNotifications);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}