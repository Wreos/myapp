import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:next_you/features/auth/screens/auth_modal.dart';

class AuthUtils {
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static Future<bool> requireAuth(BuildContext context) async {
    if (isUserLoggedIn()) {
      return true;
    }

    await showDialog(
      context: context,
      builder: (context) => const AuthModal(),
    );

    return isUserLoggedIn();
  }
}
