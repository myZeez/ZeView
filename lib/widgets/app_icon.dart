import 'dart:io';

import 'package:flutter/material.dart';

/// Shows the cached app icon file if present, otherwise a letter avatar
/// derived from the app label (the source app may have been uninstalled,
/// so the icon file might be missing or never resolved).
class AppIcon extends StatelessWidget {
  final String? iconPath;
  final String label;
  final double size;

  const AppIcon({super.key, required this.iconPath, required this.label, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final path = iconPath;
    if (path != null && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover),
      );
    }
    final letter = label.isNotEmpty ? label[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      child: Text(letter),
    );
  }
}
