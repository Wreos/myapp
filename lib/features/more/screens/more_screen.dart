import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_you/providers/theme_provider.dart';
import 'package:next_you/features/auth/providers/auth_provider.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:next_you/features/cv/screens/cv_upload_screen.dart';
import 'package:next_you/features/auth/screens/auth_modal.dart';
import 'package:next_you/features/profile/screens/profile_screen.dart';

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('SharedPreferences cleared'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing SharedPreferences: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleSignOut() async {
    try {
      // Clear CV analysis data first
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cv_analysis');

      // Reset providers and clear CV context
      ref.read(cvUploadStateProvider.notifier).resetCV();
      ref.read(cvAnalysisProvider.notifier).reset();
      ref.read(aiServiceProvider).clearCVContext();

      // Sign out after resetting state
      await ref.read(authProvider.notifier).signOut();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully signed out'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleSignIn() {
    showDialog(
      context: context,
      builder: (context) => const AuthModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surface.withOpacity(0.95)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : colorScheme.shadow.withOpacity(0.1),
        toolbarHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.outline.withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      activeColor: colorScheme.primary,
                      activeTrackColor: colorScheme.primaryContainer,
                      inactiveThumbColor: colorScheme.outline,
                      inactiveTrackColor: colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                if (user != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(user.displayName ?? 'User'),
                    subtitle: Text(user.email ?? ''),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'NextU - AI Career Coach',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(
                        Icons.work_outline,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      children: [
                        const Text(
                          'Your AI-powered career development companion. Get professional feedback on your CV and personalized career advice.',
                        ),
                      ],
                    );
                  },
                ),
                if (kDebugMode) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Clear App Data'),
                    subtitle:
                        const Text('Debug only - Clears SharedPreferences'),
                    onTap: _clearSharedPreferences,
                  ),
                ],
                authState.when(
                  data: (user) => user != null
                      ? ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Sign Out'),
                          onTap: _handleSignOut,
                        )
                      : ListTile(
                          leading: const Icon(Icons.login),
                          title: const Text('Sign In'),
                          subtitle: const Text(
                            'Sign in to save your progress and get personalized recommendations',
                          ),
                          onTap: _handleSignIn,
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
