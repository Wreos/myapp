import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool showBackground;

  const AppIcon({
    super.key,
    required this.size,
    required this.color,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (showBackground) ...[
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size * 0.22),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size * 0.15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          Center(
            child: SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.arrow_drop_up,
                      size: size * 0.25,
                      color: color,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Icon(
                      Icons.person,
                      size: size * 0.35,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
