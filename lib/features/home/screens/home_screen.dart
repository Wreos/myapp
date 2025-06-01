import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:next_you/features/auth/screens/auth_modal.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _handleFeaturePress(BuildContext context, String route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.go(route);
    } else {
      showDialog(
        context: context,
        builder: (context) => const AuthModal(),
      );
    }
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusM),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: Sizes.iconXL,
                color: isComingSoon
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: Sizes.paddingM),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isComingSoon
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Sizes.paddingS),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isComingSoon
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NextU',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _signOut,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Sizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to NextU',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: Sizes.paddingS),
                  Text(
                    'Your AI-powered career development companion',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(Sizes.paddingL),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: Sizes.paddingL,
                crossAxisSpacing: Sizes.paddingL,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _buildFeatureCard(
                  title: 'Career Chat',
                  description: 'Get personalized career guidance',
                  icon: Icons.chat_outlined,
                  onTap: () => _handleFeaturePress(context, '/chat'),
                ),
                _buildFeatureCard(
                  title: 'CV Review',
                  description: 'Get feedback on your resume',
                  icon: Icons.description_outlined,
                  onTap: () => _handleFeaturePress(context, '/'),
                ),
                _buildFeatureCard(
                  title: 'Career Goals',
                  description: 'Track your professional goals',
                  icon: Icons.track_changes_outlined,
                  onTap: () => _handleFeaturePress(context, '/goals'),
                ),
                _buildFeatureCard(
                  title: 'Weekly Review',
                  description: 'Coming Soon',
                  icon: Icons.calendar_today_outlined,
                  isComingSoon: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This feature will be available soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
