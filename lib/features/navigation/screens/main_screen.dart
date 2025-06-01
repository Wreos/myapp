import 'package:flutter/material.dart';
import 'package:next_you/features/chat/screens/chat_screen.dart';
import 'package:next_you/features/cv/screens/cv_upload_screen.dart';
import 'package:next_you/features/more/screens/more_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_you/features/cv/models/cv_feedback_model.dart';
import 'package:next_you/features/cv/screens/cv_feedback_view.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).matchedLocation;

    int _getSelectedIndex(String location) {
      switch (location) {
        case '/':
          return 0;
        case '/chat':
          return 1;
        case '/more':
          return 2;
        default:
          return 0;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/more');
              break;
          }
        },
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 60,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.description_outlined,
              color: _getSelectedIndex(location) == 0
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'CV Analysis',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.chat_outlined,
              color: _getSelectedIndex(location) == 1
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'Career Coach',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz,
              color: _getSelectedIndex(location) == 2
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
