import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirebaseAuth _auth;

  AuthNotifier(this._auth) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(FirebaseAuth.instance);
});
