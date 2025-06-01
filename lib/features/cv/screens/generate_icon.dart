import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:next_you/features/cv/screens/app_icon.dart';

class GenerateIcon extends StatefulWidget {
  const GenerateIcon({super.key});

  @override
  State<GenerateIcon> createState() => _GenerateIconState();
}

class _GenerateIconState extends State<GenerateIcon> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureIcon());
  }

  Future<void> _captureIcon() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        // Save the image data
        debugPrint('Icon captured successfully!');
      }
    } catch (e) {
      debugPrint('Error capturing icon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _globalKey,
            child: const AppIcon(
              size: 1024,
              color: Color(0xFF2196F3),
            ),
          ),
        ),
      ),
    );
  }
}
