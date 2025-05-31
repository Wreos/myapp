import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextU - Home'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'NextU Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.track_changes),
              title: const Text('Goals'),
              onTap: () {
                // Navigate to the GoalTrackerScreen (will be created later)
                Navigator.pop(context); // Close the drawer
                // TODO: Implement navigation to GoalTrackerScreen
                // Navigator.pushNamed(context, '/goals');
              },
            ),
            // Add other menu items here
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Welcome to NextU!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}