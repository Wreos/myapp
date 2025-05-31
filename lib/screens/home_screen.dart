import 'package:flutter/material.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:next_you/features/cv/screens/cv_screen.dart';
import 'package:next_you/screens/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next You'),
        elevation: 0,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(Sizes.paddingL),
        mainAxisSpacing: Sizes.paddingL,
        crossAxisSpacing: Sizes.paddingL,
        children: [
          _buildFeatureTile(
            context,
            title: 'CV Review',
            icon: Icons.description,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CVScreen()),
            ),
          ),
          _buildFeatureTile(
            context,
            title: 'Career Chat',
            icon: Icons.chat,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            ),
          ),
          _buildFeatureTile(
            context,
            title: 'Coming Soon',
            icon: Icons.track_changes,
            color: Colors.grey,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature will be available soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          _buildFeatureTile(
            context,
            title: 'Coming Soon',
            icon: Icons.trending_up,
            color: Colors.grey,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature will be available soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(Sizes.paddingL),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: Sizes.paddingM),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
