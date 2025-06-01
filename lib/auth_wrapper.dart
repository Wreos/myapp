import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:next_you/features/auth/screens/auth_screen.dart';
import 'package:next_you/features/navigation/screens/main_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStateStream;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
    _checkInitialization();
  }

  Future<void> _checkInitialization() async {
    // Wait for Firebase Auth to be fully initialized
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Navigate to MainScreen if user is authenticated
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // Navigate to AuthScreen if user is not authenticated
        return const AuthScreen();
      },
    );
  }
}
