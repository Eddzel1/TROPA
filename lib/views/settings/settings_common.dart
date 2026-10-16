import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../widgets/form_fields.dart';

/// Colors shared by the Settings & Administration tabs.
class SettingsPalette {
  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color cardBg;
  final Color border;
  final Color text;
  final Color subtext;
  final Color chipBg;
  final Color error;
  final Color success;
  final Color warning;

  SettingsPalette._(this.isDark, ColorScheme scheme)
      : primary = scheme.primary,
        onPrimary = scheme.onPrimary,
        cardBg = isDark ? TropaColors.darkSurface1dp : Colors.white,
        border = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0),
        text = isDark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface,
        subtext = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant,
        chipBg = isDark ? TropaColors.darkSurface2dp : const Color(0xFFF1F5F9),
        error = isDark ? TropaColors.errorDark : TropaColors.errorLight,
        success = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        warning = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);

  factory SettingsPalette.of(BuildContext context) =>
      SettingsPalette._(Theme.of(context).brightness == Brightness.dark, Theme.of(context).colorScheme);

  BoxDecoration get card => BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      );

  // Type scale shared with the rest of the app (see TropaText).
  TextStyle get title => TropaText.sectionTitle(text);
  TextStyle get caption => TropaText.caption(subtext);
  TextStyle get body => TropaText.body(text);
  TextStyle get bodyStrong => TropaText.bodyStrong(text);
  TextStyle get meta => TropaText.meta(subtext);
  TextStyle get fieldLabel => TropaText.fieldLabel(subtext);

  /// Small uppercase label above a value, e.g. a position name. Pass uppercase text.
  TextStyle get label => TropaText.groupLabel(subtext);
  TextStyle get tableHeader => TropaText.tableHeader(subtext);
  TextStyle get action => TropaText.action();
}

/// Card section with a title, subtitle and optional trailing actions.
class SettingsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final p = SettingsPalette.of(context);
    return Container(
      padding: padding,
      decoration: p.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: p.title),
                  if (subtitle != null) Text(subtitle!, style: p.caption),
                ],
              ),
              if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: p.border),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Small rounded label, e.g. a role, status or permission scope.
class SettingsChip extends StatelessWidget {
  final String label;
  final Color? color;

  const SettingsChip(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return TropaBadge(label, color: color);
  }
}

/// Message for an exception thrown by the service layer, without the "Exception: " prefix.
String errorMessage(Object e) => e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

void showSettingsMessage(BuildContext context, String message, {bool error = false}) {
  final p = SettingsPalette.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: error ? p.error : null),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final p = SettingsPalette.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: p.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Prompts for a single line of text; returns null when cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(title: title, label: label, initial: initial, confirmLabel: confirmLabel),
  );
}

class _PromptDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initial;
  final String confirmLabel;

  const _PromptDialog({required this.title, required this.label, required this.initial, required this.confirmLabel});

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: LabeledField(
          label: widget.label,
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: TropaStyles.fieldText(context),
            decoration: TropaStyles.formField(context),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text.trim()), child: Text(widget.confirmLabel)),
      ],
    );
  }
}
