import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // Initialize and check if user is logged in
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    final user = await _authService.getCurrentUser();
    _currentUser = user;
    
    _isLoading = false;
    notifyListeners();
  }

  // Sign up
  Future<String?> signUp(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.signUp(user);
      _isLoading = false;
      notifyListeners();

      if (success) {
        return null; // Success
      } else {
        return 'Email already exists';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign up failed. Please try again.';
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _authService.login(email, password);
      
      if (success) {
        _currentUser = await _authService.getCurrentUser();
        _isLoading = false;
        notifyListeners();
        return null; // Success
      } else {
        _isLoading = false;
        notifyListeners();
        return 'Invalid email or password';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Login failed. Please try again.';
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    
    _isLoading = false;
    notifyListeners();
  }

  // Update profile
  Future<String?> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String role,
     required String profilePhotoUrl,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return 'Email cannot be empty.';
    }

    _isLoading = true;
    notifyListeners();

    final updated = await _authService.updateCurrentUser(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: trimmedEmail,
      role: role,
      profilePhotoUrl: profilePhotoUrl,
    );

    _isLoading = false;

    if (updated == null) {
      notifyListeners();
      return 'Failed to update profile. Please try again.';
    }

    _currentUser = updated;
    notifyListeners();
    return null;
  }
}


