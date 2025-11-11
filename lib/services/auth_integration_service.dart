import 'shared_prefs_service.dart';
// services/auth_integration_service.dart
class AuthIntegrationService {
  static Future<String?> getCurrentUserId() async {
    // Point d'intégration avec le module d'authentification
    // Pour l'instant, on utilise SharedPreferences
    // Votre collègue devra implémenter cette méthode
    
    // Méthode temporaire en attendant l'intégration
    return SharedPrefsService.getUserPhone();
  }

  static Future<bool> isUserLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null && userId.isNotEmpty;
  }

  static Future<void> onUserLogin(String userId) async {
    // Appelé quand un utilisateur se connecte
    await SharedPrefsService.setUserPhone(userId);
  }

  static Future<void> onUserLogout() async {
    // Appelé quand un utilisateur se déconnecte
    await SharedPrefsService.clearAll();
  }
}