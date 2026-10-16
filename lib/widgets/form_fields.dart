import 'package:flutter/material.dart';
import '../core/design_system.dart';

/// A form field with its label above it, as in the Add TROPA Member dialog.
/// Pair the field with `TropaStyles.formField` and `TropaStyles.fieldText`.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TropaText.fieldLabel(subtext)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Small pill label for statuses and tags, e.g. "TROPA MEMBER" or "VOTER".
class TropaBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const TropaBadge(this.text, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? TropaColors.primaryOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
          Text(text, style: TropaText.badge(c)),
        ],
      ),
    );
  }
}

/// Form section header with a divider under it, e.g. "Personal Information".
class SectionHeader extends StatelessWidget {
  final String title;
  final List<Widget> trailing;

  const SectionHeader(this.title, {super.key, this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [Text(title, style: TropaText.sectionHeader(scheme.onSurface)), ...trailing],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, thickness: 1, color: TropaColors.borderOf(context)),
      ],
    );
  }
}
