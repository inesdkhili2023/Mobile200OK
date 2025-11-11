/// Interface pour l'authentification
/// Votre collègue implémentera cette classe
abstract class IAuthService {
  // État de connexion
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isAuthenticated;
  
  // Méthodes à implémenter par votre collègue
  Future<bool> signIn(String email, String password);
  Future<bool> signUp(String email, String password, Map<String, dynamic> userData);
  Future<void> signOut();
  
  // Stream pour écouter les changements
  Stream<String?> get authStateChanges;
}

/// Implémentation temporaire pour vos tests
class MockAuthService implements IAuthService {
  String? _userId = 'test_user_123';
  
  @override
  String? get currentUserId => _userId;
  
  @override
  String? get currentUserEmail => 'test@example.com';
  
  @override
  bool get isAuthenticated => _userId != null;
  
  @override
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    return true;
  }
  
  @override
  Future<bool> signUp(String email, String password, Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(seconds: 1));
    _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    return true;
  }
  
  @override
  Future<void> signOut() async {
    _userId = null;
  }
  
  @override
  Stream<String?> get authStateChanges {
    return Stream.value(_userId);
  }
}