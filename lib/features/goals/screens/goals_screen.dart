import 'package:flutter/material.dart';
import 'package:next_you/constants/sizes.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Widget _buildGoalCard({
    required String title,
    required String description,
    required double progress,
    required String deadline,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: Sizes.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Sizes.radiusM),
        child: Padding(
          padding: EdgeInsets.all(Sizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    deadline,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: Sizes.paddingS),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: Sizes.paddingM),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Sizes.radiusS),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  SizedBox(width: Sizes.paddingM),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Career Goals',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add goal
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(Sizes.paddingL),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildGoalCard(
                    title: 'Learn Flutter Development',
                    description:
                        'Complete advanced Flutter course and build 3 portfolio projects',
                    progress: 0.7,
                    deadline: 'Mar 2024',
                  ),
                  _buildGoalCard(
                    title: 'Get AWS Certification',
                    description:
                        'Study and pass the AWS Solutions Architect exam',
                    progress: 0.3,
                    deadline: 'Jun 2024',
                  ),
                  _buildGoalCard(
                    title: 'Improve Leadership Skills',
                    description:
                        'Lead a team project and mentor junior developers',
                    progress: 0.5,
                    deadline: 'Dec 2024',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement AI goal suggestions
        },
        icon: const Icon(Icons.psychology),
        label: const Text('AI Suggestions'),
      ),
    );
  }
}
