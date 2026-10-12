import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MasteraLogo extends StatelessWidget {
  final double fontSize;
  final bool compact;
  final bool light;

  const MasteraLogo({
    super.key,
    this.fontSize = 24,
    this.compact = false,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppTheme.ink;
    final badgeColor = light ? Colors.white : AppTheme.accent;
    final badgeTextColor = light ? AppTheme.primary : Colors.white;
    final badgeRadius = compact ? 10.0 : 12.0;
    final verticalPadding = compact ? 6.0 : 7.0;
    final horizontalPadding = compact ? 9.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MASTERA',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: fontSize,
            color: textColor,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 0.8 : 1.2,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(badgeRadius),
          ),
          child: Text(
            '24',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: badgeTextColor,
              fontWeight: FontWeight.w800,
              fontSize: compact ? fontSize * 0.54 : fontSize * 0.58,
            ),
          ),
        ),
      ],
    );
  }
}
