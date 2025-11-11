import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'email_service.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _verificationCodeKey = 'verification_code';
  static const String _verificationEmailKey = 'verification_email';
  static const String _verificationCodeExpiryKey = 'verification_code_expiry';
  static const String _signupVerificationCodeKey = 'signup_verification_code';
  static const String _signupVerificationCodeExpiryKey = 'signup_verification_code_expiry';
  static const String _pendingSignupKey = 'pending_signup';

  // Sign up a new user
  Future<bool> signUp(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      List<User> users = [];
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        users = usersList.map((u) => User.fromJson(u)).toList();
      }

      // Check if user already exists
      if (users.any((u) => u.email == user.email)) {
        return false; // User already exists
      }

      // Generate sequential ID if not provided
      String userId = user.id;
      if (userId.isEmpty) {
        // Get the highest existing ID and increment
        int maxId = 0;
        for (var u in users) {
          try {
            final idNum = int.parse(u.id);
            if (idNum > maxId) {
              maxId = idNum;
            }
          } catch (e) {
            // If ID is not a number, ignore it
          }
        }
        userId = (maxId + 1).toString();
      }

      final userWithId = User(
        id: userId,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        profilePhotoUrl: user.profilePhotoUrl,
        password: user.password,
      );

      // Add new user
      users.add(userWithId);
      final updatedUsersJson = json.encode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, updatedUsersJson);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        return false;
      }

      final List<dynamic> usersList = json.decode(usersJson);
      final List<User> users = usersList.map((u) => User.fromJson(u)).toList();

      // Find user with matching email and password
      final user = users.firstWhere(
        (u) => u.email == email && u.password == password,
        orElse: () => User(
          id: '',
          fullName: '',
          email: '',
          phoneNumber: '',
          role: '',
        ),
      );

      if (user.email.isEmpty) {
        return false; // User not found or wrong password
      }

      // Save current user (without password for security)
      final currentUser = User(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        profilePhotoUrl: user.profilePhotoUrl,
      );
      
      await prefs.setString(_currentUserKey, json.encode(currentUser.toJson()));
      await prefs.setBool(_isLoggedInKey, true);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (!isLoggedIn) {
        return null;
      }

      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) {
        return null;
      }

      return User.fromJson(json.decode(userJson));
    } catch (e) {
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      // Handle error
    }
  }

  // Generate verification code for password reset
  Future<Map<String, dynamic>> generateVerificationCode(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        return {'success': false, 'error': 'No users found'};
      }

      final List<dynamic> usersList = json.decode(usersJson);
      final List<User> users = usersList.map((u) => User.fromJson(u)).toList();

      // Check if user exists
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => User(
          id: '',
          fullName: '',
          email: '',
          phoneNumber: '',
          role: '',
        ),
      );

      if (user.email.isEmpty) {
        return {'success': false, 'error': 'User not found'};
      }

      // Generate 6-digit verification code
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Store code, email, and expiry (10 minutes from now)
      final expiryTime = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
      
      await prefs.setString(_verificationCodeKey, code);
      await prefs.setString(_verificationEmailKey, email);
      await prefs.setInt(_verificationCodeExpiryKey, expiryTime);
      
      // Send email via EmailJS
      final emailService = EmailService();
      if (emailService.isConfigured()) {
        final emailSent = await emailService.sendVerificationEmail(
          toEmail: email,
          verificationCode: code,
          userName: user.fullName,
        );
        
        if (emailSent) {
          return {'success': true, 'code': code, 'emailSent': true};
        } else {
          // Code is stored, but email failed to send
          return {'success': true, 'code': code, 'emailSent': false, 'error': 'Failed to send email'};
        }
      } else {
        // EmailJS not configured, return code for testing
        return {'success': true, 'code': code, 'emailSent': false, 'error': 'EmailJS not configured'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify verification code
  Future<bool> verifyCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCode = prefs.getString(_verificationCodeKey);
      final expiryTime = prefs.getInt(_verificationCodeExpiryKey);
      
      if (storedCode == null || expiryTime == null) {
        return false; // No code stored
      }

      // Check if code has expired
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        // Clear expired code
        await prefs.remove(_verificationCodeKey);
        await prefs.remove(_verificationEmailKey);
        await prefs.remove(_verificationCodeExpiryKey);
        return false; // Code expired
      }

      // Verify code
      if (storedCode != code) {
        return false; // Invalid code
      }

      return true; // Code is valid
    } catch (e) {
      return false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_verificationEmailKey);
      
      if (email == null) {
        return false; // No email associated with verification
      }

      final usersJson = prefs.getString(_usersKey);
      if (usersJson == null) {
        return false;
      }

      final List<dynamic> usersList = json.decode(usersJson);
      List<User> users = usersList.map((u) => User.fromJson(u)).toList();

      // Find user and update password
      final userIndex = users.indexWhere((u) => u.email == email);
      if (userIndex == -1) {
        return false; // User not found
      }

      // Update user password
      final updatedUser = User(
        id: users[userIndex].id,
        fullName: users[userIndex].fullName,
        email: users[userIndex].email,
        phoneNumber: users[userIndex].phoneNumber,
        role: users[userIndex].role,
        profilePhotoUrl: users[userIndex].profilePhotoUrl,
        password: newPassword,
      );

      users[userIndex] = updatedUser;
      final updatedUsersJson = json.encode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, updatedUsersJson);

      // Clear verification data
      await prefs.remove(_verificationCodeKey);
      await prefs.remove(_verificationEmailKey);
      await prefs.remove(_verificationCodeExpiryKey);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get email associated with verification (for reset password page)
  Future<String?> getVerificationEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_verificationEmailKey);
    } catch (e) {
      return null;
    }
  }

  // Update current user's profile (fullName, phoneNumber, role)
  Future<User?> updateCurrentUser({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String role,
    required String profilePhotoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString(_currentUserKey);
      final usersJson = prefs.getString(_usersKey);

      if (currentUserJson == null || usersJson == null) {
        return null;
      }

      final currentUser = User.fromJson(json.decode(currentUserJson));

      // Update in users list
      final List<dynamic> usersList = json.decode(usersJson);
      List<User> users = usersList.map((u) => User.fromJson(u)).toList();
      final index = users.indexWhere((u) => u.email == currentUser.email);
      if (index == -1) {
        return null;
      }

      final normalizedEmail = email.trim();
      final currentEmailLower = currentUser.email.toLowerCase();
      final emailExists = users.any(
        (u) =>
            u.email.toLowerCase() == normalizedEmail.toLowerCase() &&
            u.email.toLowerCase() != currentEmailLower,
      );

      if (normalizedEmail.isEmpty || emailExists) {
        return null;
      }

      final updatedUser = User(
        id: users[index].id,
        fullName: fullName,
        email: normalizedEmail,
        phoneNumber: phoneNumber,
        role: role,
        password: users[index].password,
        profilePhotoUrl: profilePhotoUrl,
      );

      users[index] = updatedUser;
      await prefs.setString(_usersKey, json.encode(users.map((u) => u.toJson()).toList()));
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toJson()));

      return updatedUser;
    } catch (e) {
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        return null;
      }

      final List<dynamic> usersList = json.decode(usersJson);
      final List<User> users = usersList.map((u) => User.fromJson(u)).toList();

      // Find user with matching ID
      try {
        final user = users.firstWhere((u) => u.id == id);
        return user;
      } catch (e) {
        return null; // User not found
      }
    } catch (e) {
      return null;
    }
  }

  // Get all users (for database viewing)
  Future<List<User>> getAllUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) {
        return [];
      }

      final List<dynamic> usersList = json.decode(usersJson);
      return usersList.map((u) => User.fromJson(u)).toList();
    } catch (e) {
      return [];
    }
  }

  // Generate verification code for signup
  Future<Map<String, dynamic>> generateSignupVerificationCode(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson != null) {
        final List<dynamic> usersList = json.decode(usersJson);
        final List<User> users = usersList.map((u) => User.fromJson(u)).toList();

        // Check if user already exists
        if (users.any((u) => u.email == user.email)) {
          return {'success': false, 'error': 'Email already exists'};
        }
      }

      // Generate 6-digit verification code
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Store code, user data, and expiry (10 minutes from now)
      final expiryTime = DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;
      
      await prefs.setString(_signupVerificationCodeKey, code);
      await prefs.setInt(_signupVerificationCodeExpiryKey, expiryTime);
      await prefs.setString(_pendingSignupKey, json.encode(user.toJson()));
      
      // Send email via EmailJS
      final emailService = EmailService();
      if (emailService.isConfigured()) {
        final emailSent = await emailService.sendSignupVerificationEmail(
          toEmail: user.email,
          verificationCode: code,
          userName: user.fullName,
        );
        
        if (emailSent) {
          return {'success': true, 'code': code, 'emailSent': true};
        } else {
          // Code is stored, but email failed to send
          return {'success': true, 'code': code, 'emailSent': false, 'error': 'Failed to send email'};
        }
      } else {
        // EmailJS not configured, return code for testing
        return {'success': true, 'code': code, 'emailSent': false, 'error': 'EmailJS not configured'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Verify signup verification code
  Future<bool> verifySignupCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCode = prefs.getString(_signupVerificationCodeKey);
      final expiryTime = prefs.getInt(_signupVerificationCodeExpiryKey);
      
      if (storedCode == null || expiryTime == null) {
        return false; // No code stored
      }

      // Check if code has expired
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        // Clear expired code
        await prefs.remove(_signupVerificationCodeKey);
        await prefs.remove(_signupVerificationCodeExpiryKey);
        await prefs.remove(_pendingSignupKey);
        return false; // Code expired
      }

      // Verify code
      if (storedCode != code) {
        return false; // Invalid code
      }

      return true; // Code is valid
    } catch (e) {
      return false;
    }
  }

  // Complete signup after verification
  Future<bool> completeSignup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSignupJson = prefs.getString(_pendingSignupKey);
      
      if (pendingSignupJson == null) {
        return false; // No pending signup
      }

      final user = User.fromJson(json.decode(pendingSignupJson));
      
      // Now create the user account
      final success = await signUp(user);
      
      if (success) {
        // Clear verification data
        await prefs.remove(_signupVerificationCodeKey);
        await prefs.remove(_signupVerificationCodeExpiryKey);
        await prefs.remove(_pendingSignupKey);
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Resend signup verification code
  Future<Map<String, dynamic>> resendSignupVerificationCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSignupJson = prefs.getString(_pendingSignupKey);
      
      if (pendingSignupJson == null) {
        return {'success': false, 'error': 'No pending signup found'};
      }

      final user = User.fromJson(json.decode(pendingSignupJson));
      return await generateSignupVerificationCode(user);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
