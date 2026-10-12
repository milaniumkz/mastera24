import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumLayout {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1120;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 760;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1440) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 32);
    }
    if (width >= 1120) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 18, vertical: 18);
  }

  static double maxWidth(BuildContext context, {double desktop = 1360}) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1480) {
      return desktop;
    }
    if (width >= 1120) {
      return width - 48;
    }
    return 760;
  }
}

class PremiumPageBody extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const PremiumPageBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.pageBackdrop(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                maxWidth ?? PremiumLayout.maxWidth(context, desktop: 1380),
          ),
          child: Padding(
            padding: padding ?? PremiumLayout.pagePadding(context),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PremiumPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool accented;
  final bool darker;

  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.accented = false,
    this.darker = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.premiumPanelDecoration(
        accented: accented,
        darker: darker,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class PremiumHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> stats;
  final Widget? trailing;
  final bool darker;
  final int? subtitleMaxLines;

  const PremiumHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.stats = const [],
    this.trailing,
    this.darker = true,
    this.subtitleMaxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = PremiumLayout.isDesktop(context);

    return PremiumPanel(
      darker: darker,
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _heroCopy(eyebrow, title, subtitle, stats)),
                if (trailing != null) ...[
                  const SizedBox(width: 24),
                  Flexible(child: trailing!),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCopy(eyebrow, title, subtitle, stats),
                if (trailing != null) ...[
                  const SizedBox(height: 18),
                  trailing!,
                ],
              ],
            ),
    );
  }

  Widget _heroCopy(
    String eyebrow,
    String title,
    String subtitle,
    List<Widget> stats,
  ) {
    return Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow.trim().isNotEmpty) ...[
              Text(
                eyebrow.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: darker ? AppTheme.accentSoft : AppTheme.accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              title,
              style: textTheme.displayMedium?.copyWith(
                fontSize: PremiumLayout.isDesktop(context) ? 26 : 20,
                color: darker ? Colors.white : AppTheme.ink,
              ),
            ),
            if (subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: subtitleMaxLines,
                overflow: subtitleMaxLines == null
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: darker
                      ? Colors.white.withValues(alpha: 0.76)
                      : AppTheme.inkSoft,
                ),
              ),
            ],
            if (stats.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: stats),
            ],
          ],
        );
      },
    );
  }
}

class PremiumStatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool light;

  const PremiumStatChip({
    super.key,
    required this.label,
    required this.value,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color bg = light
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.1);
    final Color border = light
        ? AppTheme.line
        : Colors.white.withValues(alpha: 0.14);
    final Color titleColor = light ? AppTheme.inkSoft : AppTheme.accentSoft;
    final Color valueColor = light ? AppTheme.ink : Colors.white;

    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall?.copyWith(color: titleColor)),
          const SizedBox(height: 2),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CompactSummaryBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool dense;

  const CompactSummaryBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = PremiumLayout.isDesktop(context);
    final textTheme = Theme.of(context).textTheme;

    return PremiumPanel(
      accented: true,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: dense ? 12 : 14,
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _copy(textTheme)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _copy(textTheme),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            ),
    );
  }

  Widget _copy(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.headlineSmall?.copyWith(fontSize: 20)),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: textTheme.bodySmall),
        ],
      ],
    );
  }
}

class PremiumSplitLayout extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double spacing;

  const PremiumSplitLayout({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
    this.spacing = 22,
  });

  @override
  Widget build(BuildContext context) {
    if (!PremiumLayout.isDesktop(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          SizedBox(height: spacing),
          secondary,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: primaryFlex, child: primary),
        SizedBox(width: spacing),
        Expanded(flex: secondaryFlex, child: secondary),
      ],
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.diamond_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumPanel(
      accented: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(height: 18),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}
