import 'package:flutter/material.dart';
import '../core/design_system.dart';

/// Page title, subtitle and actions. Actions sit to the right on wide screens and drop below the
/// title on narrow ones, so long titles never push them off screen.
class TropaPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Shown after the title, e.g. a badge.
  final Widget? titleTrailing;

  /// Extra lines under the subtitle.
  final List<Widget> below;
  final List<Widget> actions;

  const TropaPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleTrailing,
    this.below = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textCol = TropaColors.textHigh(context);
    final subtextCol = TropaColors.textMedium(context);

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: TropaText.pageTitle(textCol)),
            if (titleTrailing != null) titleTrailing!,
          ],
        ),
        if (subtitle != null) Text(subtitle!, style: TropaText.meta(subtextCol)),
        ...below,
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (actions.isEmpty) return info;
      if (constraints.maxWidth >= 700) {
        return Row(
          children: [
            Expanded(child: info),
            const SizedBox(width: 16),
            for (final (i, a) in actions.indexed) ...[if (i > 0) const SizedBox(width: 10), a],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          info,
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 8, children: actions),
        ],
      );
    });
  }
}
