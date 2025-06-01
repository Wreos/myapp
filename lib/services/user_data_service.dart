import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/services/ai_service.dart';

final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService(ref.read(aiServiceProvider));
});

class UserDataService {
  final AIService _aiService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserDataService(this._aiService);

  /// Deletes all user data and account
  Future<void> deleteUserData() async {
    try {
      // Clear AI service data
      await _aiService.clearUserData();

      // Get current user
      final user = _auth.currentUser;
      if (user != null) {
        // Delete the user account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  /// Exports user data in a GDPR-compliant format
  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      return {
        'userData': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'creationTime': user.metadata.creationTime?.toIso8601String(),
          'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        },
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  /// Updates user data with GDPR compliance
  Future<void> updateUserData({
    String? displayName,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (email != null) {
        await user.updateEmail(email);
      }
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}
