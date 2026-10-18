import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system.dart';

/// Shows and stores typed text in upper case. Upper-casing keeps the length, so the cursor stays put.
/// Pair with `textCapitalization: TextCapitalization.characters` so phone keyboards open in caps.
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

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
          Flexible(child: Text(text, style: TropaText.badge(c), overflow: TextOverflow.ellipsis, maxLines: 1)),
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

/// A row of form fields that stacks into a column on phones: `Expanded`/`Flexible` children are
/// unwrapped and horizontal `SizedBox` gaps become vertical ones. Wider screens get a plain [Row].
class ResponsiveFieldRow extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveFieldRow({super.key, required this.children, this.crossAxisAlignment = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    if (!context.isCompactScreen) {
      return Row(crossAxisAlignment: crossAxisAlignment, children: children);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in children)
          switch (c) {
            Flexible(:final child) => child,
            SizedBox(width: final w?, child: null) when w > 0 => const SizedBox(height: 14),
            _ => c,
          },
      ],
    );
  }
}
