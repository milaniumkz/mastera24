import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'safe_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double radius;
  final bool bordered;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
    this.bordered = false,
  });

  String _initials(String? value) {
    final parts = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '';
    }
    if (parts.length == 1) {
      return String.fromCharCode(parts.first.runes.first).toUpperCase();
    }
    return '${String.fromCharCode(parts.first.runes.first).toUpperCase()}'
        '${String.fromCharCode(parts.last.runes.first).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final initials = _initials(name);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: AppTheme.line) : null,
        color: AppTheme.accentSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? SafeNetworkImage(
              imageUrl: imageUrl!.trim(),
              width: size,
              height: size,
              fit: BoxFit.cover,
            )
          : Center(
              child: initials.isNotEmpty
                  ? Text(
                      initials,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: radius,
                      color: AppTheme.primary,
                    ),
            ),
    );
  }
}
