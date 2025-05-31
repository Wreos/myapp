import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState(); // Corrected createState signature
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextU - Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to NextU!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator() // Use child for Center, but not directly in Column
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton( // ElevatedButton correctly uses 'child'
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text( // Text widget is the child of ElevatedButton
                        'Sign in with Google',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Show Apple Sign-in only on platforms where it's supported
                    if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS) // Correct conditional logic
                      SignInWithAppleButton( // Use SignInWithAppleButton for a more standard look
                        onPressed: _signInWithApple,
                        style: SignInWithAppleButtonStyle.black, // Or SignInWithAppleButtonStyle.white
                        // The button automatically handles its text content.
                      ),
                  ],
                ), // Column correctly uses 'children'
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Sign in was aborted by the user
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      // Handle errors here
      print(e); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    }); // This is more complex and requires specific setup in Firebase and Apple Developer account
    try { // Corrected to use performRequests
      final credential = await SignInWithApple.getAppleIDCredential(
        requests: [ // Changed from 'request' to 'requests' based on package documentation
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // You'll need to generate and use a secure nonce for security purposes.
        nonce: '', // Placeholder for the nonce
        // You might need to configure the nonce and state parameters for security
        // see: https://firebase.google.com/docs/auth/ios/apple#nonce
      );

      final appleProvider = AppleAuthProvider(
        credential: OAuthCredential(
          providerId: 'apple.com',
          accessToken: String.fromCharCodes(credential.authorizationCode),
          idToken: String.fromCharCodes(credential.identityToken!), // Pass identityToken as String
          rawNonce: '', // Replace with actual nonce if used
        ),
      );
y
      await _auth.signInWithCredential(appleProvider.credential!);
      print('Apple Sign-in pressed');
    } catch (e) {
      print(e); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Apple: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}