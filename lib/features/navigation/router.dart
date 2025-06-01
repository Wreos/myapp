import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../cv/screens/cv_upload_screen.dart';
import '../cv/screens/cv_feedback_view.dart';
import '../chat/screens/chat_screen.dart';
import '../more/screens/more_screen.dart';
import '../goals/screens/goals_screen.dart';
import '../auth/services/auth_service.dart';
import 'screens/main_screen.dart';
import '../cv/models/cv_feedback_model.dart';
import '../profile/screens/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authService = AuthService();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CVUploadScreen(),
            routes: [
              GoRoute(
                path: 'feedback',
                pageBuilder: (context, state) {
                  final analysis = state.extra as Map<String, dynamic>;
                  final feedback = CVFeedback.fromJson(analysis);
                  return MaterialPage(
                    fullscreenDialog: true,
                    child: CVFeedbackView(
                      feedback: feedback,
                      onChatPressed: () => context.go('/chat'),
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// Helper class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
