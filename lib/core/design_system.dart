import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_palettes.dart';

/// Fixed colours that stay the same in every theme. Themed colours (text, surfaces, borders,
/// primary/accent) come from the active palette in `theme_palettes.dart`; read them through the
/// helpers below rather than hard-coding light/dark pairs.
class TropaColors {
  // Data accents: teal for inactive map pins and new-record badges.
  static const secondary = Color(0xFF03DAC6);          // Teal 200
  static const secondaryVariant = Color(0xFF018786);   // Teal 700
  static const tertiary = secondary;

  // Error palette, light and dark
  static const errorLight = Color(0xFFB00020);
  static const errorDark = Color(0xFFCF6679);
  static const onErrorLight = Color(0xFFFFFFFF);
  static const onErrorDark = Color(0xFF000000);
  static const error = errorDark;
  static const errorContainer = Color(0xFFCF6679);

  // TROPA brand palette (used by the TROPA theme and the startup screen)
  static const tropaBlue = Color(0xFF1F4DAA);
  static const tropaGreen = Color(0xFF60B358);
  static const tropaWhite = Color(0xFFFFFFFF);

  // Status
  static const offline = Color(0xFFF5A623);           // Amber: working offline, changes queued

  // Theme-aware helper methods. Every palette fills the same ColorScheme roles (see
  // TropaTheme.of), so these follow whichever theme is active.
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color onPrimaryOf(BuildContext context) => Theme.of(context).colorScheme.onPrimary;

  /// Accent color of the active palette.
  static Color secondaryOf(BuildContext context) => Theme.of(context).colorScheme.secondary;

  /// Higher-contrast accent for text/icons on surfaces.
  static Color secondaryStrongOf(BuildContext context) => Theme.of(context).colorScheme.tertiary;

  static Color backgroundOf(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  static Color surfaceOf(BuildContext context, [int dp = 1]) {
    if (dp == 0) return backgroundOf(context);
    return dp <= 1 ? cardOf(context) : chipOf(context);
  }

  /// Cards, dialogs, menus and dropdowns.
  static Color cardOf(BuildContext context) => Theme.of(context).colorScheme.surface;

  /// Panels set off slightly from the card or dialog they sit in.
  static Color subtleOf(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLow;

  /// Chips, icon tiles, table headers and lanes.
  static Color chipOf(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Fill of text fields and dropdown buttons.
  static Color fieldFillOf(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerLowest;

  static Color textHigh(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  static Color textMedium(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  static Color textDisabled(BuildContext context) => Theme.of(context).colorScheme.outline;

  static Color borderOf(BuildContext context) => Theme.of(context).colorScheme.outlineVariant;

  static Color errorOf(BuildContext context) => Theme.of(context).colorScheme.error;

  static Color onErrorOf(BuildContext context) => Theme.of(context).colorScheme.onError;
}

/// Branding attached only to the TROPA theme (solid blue sidebar).
class TropaBrand extends ThemeExtension<TropaBrand> {
  final Color sidebarBg;
  final Color sidebarFg;
  final Color sidebarFgMuted;
  final Color sidebarActiveBg;
  final Color sidebarActiveFg;

  const TropaBrand({
    required this.sidebarBg,
    required this.sidebarFg,
    required this.sidebarFgMuted,
    required this.sidebarActiveBg,
    required this.sidebarActiveFg,
  });

  @override
  TropaBrand copyWith({
    Color? sidebarBg,
    Color? sidebarFg,
    Color? sidebarFgMuted,
    Color? sidebarActiveBg,
    Color? sidebarActiveFg,
  }) =>
      TropaBrand(
        sidebarBg: sidebarBg ?? this.sidebarBg,
        sidebarFg: sidebarFg ?? this.sidebarFg,
        sidebarFgMuted: sidebarFgMuted ?? this.sidebarFgMuted,
        sidebarActiveBg: sidebarActiveBg ?? this.sidebarActiveBg,
        sidebarActiveFg: sidebarActiveFg ?? this.sidebarActiveFg,
      );

  @override
  TropaBrand lerp(ThemeExtension<TropaBrand>? other, double t) {
    if (other is! TropaBrand) return this;
    return TropaBrand(
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      sidebarFg: Color.lerp(sidebarFg, other.sidebarFg, t)!,
      sidebarFgMuted: Color.lerp(sidebarFgMuted, other.sidebarFgMuted, t)!,
      sidebarActiveBg: Color.lerp(sidebarActiveBg, other.sidebarActiveBg, t)!,
      sidebarActiveFg: Color.lerp(sidebarActiveFg, other.sidebarActiveFg, t)!,
    );
  }
}

class TropaTheme {
  // Outlined/text buttons otherwise default to Material 3 pill shapes; match the elevated buttons.
  static OutlinedButtonThemeData get _outlinedButtonTheme => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  /// Type for dialogs, menus, snackbars, date pickers and fields, matching the Add Member dialog.
  static ThemeData _withTypography(ThemeData t) {
    final scheme = t.colorScheme;
    return t.copyWith(
      dialogTheme: t.dialogTheme.copyWith(
        titleTextStyle: TropaText.dialogTitle(scheme.onSurface),
        contentTextStyle: TropaText.body(scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      popupMenuTheme: t.popupMenuTheme.copyWith(textStyle: TropaText.body(scheme.onSurface)),
      // Tabs and toggles use the app's Inter scale and primary colour instead of Material defaults.
      tabBarTheme: t.tabBarTheme.copyWith(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant,
        labelStyle: TropaText.bodyStrong(scheme.primary),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? scheme.primary.withValues(alpha: 0.1) : Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ),
      snackBarTheme: t.snackBarTheme.copyWith(contentTextStyle: TropaText.body(scheme.onInverseSurface)),
      datePickerTheme: t.datePickerTheme.copyWith(
        headerHelpStyle: TropaText.fieldLabel(scheme.onSurfaceVariant),
        headerHeadlineStyle: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
        weekdayStyle: TropaText.meta(scheme.onSurfaceVariant),
        dayStyle: GoogleFonts.inter(fontSize: 13),
        yearStyle: GoogleFonts.inter(fontSize: 13),
        rangePickerHeaderHeadlineStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: t.inputDecorationTheme.copyWith(
        labelStyle: TropaText.body(scheme.onSurfaceVariant),
        hintStyle: TropaText.body(scheme.onSurfaceVariant.withValues(alpha: 0.75)),
        helperStyle: TropaText.caption(scheme.onSurfaceVariant),
        errorStyle: GoogleFonts.inter(fontSize: 11, color: scheme.error),
      ),
    );
  }

  // Built once per palette and reused; rebuilding ThemeData on every app rebuild is wasted work.
  static final Map<String, ThemeData> _cache = {};

  /// The ThemeData for a palette id from `tropaPalettes`; unknown ids get the TROPA theme.
  static ThemeData of(String id) {
    final palette = tropaPaletteById(id);
    return _cache.putIfAbsent(palette.id, () => _withTypography(_build(palette)));
  }

  static ThemeData get tropaTheme => of(TropaPalette.defaultId);

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// [fg] made darker (lighter on a dark [bg]) until it reaches WCAG AA, 4.5:1, on [bg]. Only the
  /// lightness changes, so a pale pastel becomes a deeper shade of the same hue rather than grey.
  static Color _readable(Color fg, Color bg) {
    if (_contrast(fg, bg) >= 4.5) return fg;
    final hsl = HSLColor.fromColor(fg);
    final darken = bg.computeLuminance() > 0.5;
    for (var step = 1; step <= 50; step++) {
      final l = (hsl.lightness + (darken ? -step : step) * 0.02).clamp(0.0, 1.0);
      final c = hsl.withLightness(l).toColor();
      if (_contrast(c, bg) >= 4.5) return c;
    }
    return darken ? Colors.black : Colors.white;
  }

  /// Near-black or white, whichever reads better on [c].
  static Color _onColor(Color c) {
    const ink = Color(0xFF0B0B0F);
    return _contrast(Colors.white, c) >= _contrast(ink, c) ? Colors.white : ink;
  }

  static ThemeData _build(TropaPalette p) {
    final dark = p.brightness == Brightness.dark;
    final baseTextTheme = dark ? Typography.material2021().white : Typography.material2021().black;
    final faint = p.text.withValues(alpha: 0.38); // disabled text, hints, empty-state icons
    // Accent and muted colours are drawn as text and icons on cards, so they are nudged darker
    // (lighter on dark palettes) until readable; the picker swatch keeps the palette's own colour.
    final accent = _readable(p.secondary, p.surface);
    final muted = _readable(p.muted, p.surfaceVariant);
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.surfaceVariant,
      onPrimaryContainer: p.accentText,
      secondary: accent,
      onSecondary: _onColor(accent),
      secondaryContainer: p.surfaceVariant,
      onSecondaryContainer: p.accentText,
      tertiary: _readable(p.accentText, p.surface),
      onTertiary: p.onPrimary,
      error: dark ? TropaColors.errorDark : TropaColors.errorLight,
      onError: dark ? TropaColors.onErrorDark : TropaColors.onErrorLight,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: muted,
      // Fields sit lighter than cards on light palettes and darker on dark ones, as before.
      surfaceContainerLowest: dark ? p.background : p.surface,
      surfaceContainerLow: Color.lerp(p.surface, p.surfaceVariant, 0.5),
      surfaceContainer: p.surfaceVariant,
      surfaceContainerHigh: p.surfaceVariant,
      surfaceContainerHighest: p.surfaceVariant,
      outline: faint,
      outlineVariant: p.border,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      dividerColor: p.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: faint),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(p.onPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary;
          }
          return faint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary.withValues(alpha: 0.5);
          }
          return p.surfaceVariant;
        }),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: p.text,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: p.text,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: muted,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: faint,
        ),
      ),
      extensions: [if (p.brand != null) p.brand!],
    );
  }
}

/// The app's type scale, taken from the Add TROPA Member dialog. Manrope is reserved for page
/// titles, dialog titles and big stat numbers; everything inside cards, tables and forms is Inter.
class TropaText {
  static TextStyle pageTitle(Color c) => GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: c);
  static TextStyle dialogTitle(Color c) => GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: c);
  static TextStyle kpi(Color c, {double size = 24}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: c);

  /// Card and section titles, e.g. "Household Members".
  static TextStyle sectionTitle(Color c) => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: c);

  /// Form section header above a divider, e.g. "Personal Information".
  static TextStyle sectionHeader(Color c) => GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: c);

  static TextStyle body(Color c) => GoogleFonts.inter(fontSize: 13, color: c);
  static TextStyle bodyStrong(Color c) => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: c);

  /// Secondary detail: table cells, IDs, amounts, dates. Tabular figures keep numbers aligned.
  static TextStyle meta(Color c) =>
      GoogleFonts.inter(fontSize: 12, color: c, fontFeatures: const [FontFeature.tabularFigures()]);

  /// Help text and subtitles.
  static TextStyle caption(Color c) => GoogleFonts.inter(fontSize: 11.5, color: c);

  /// Label above a form field.
  static TextStyle fieldLabel(Color c) => GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: c);

  /// Small uppercase group label, e.g. "LOCATION". Pass uppercase text.
  static TextStyle groupLabel(Color c) =>
      GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: c);

  static TextStyle tableHeader(Color c) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: c);

  static TextStyle badge(Color c) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: c);

  /// Text of buttons and links inside cards and dialogs.
  static TextStyle action([Color? c]) => GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: c);
}

/// Shared styles for page chrome (header actions, filter bars) so every view matches.
class TropaStyles {
  /// Filled page-header action, e.g. "Add Member".
  static ButtonStyle primaryAction(BuildContext context) => ElevatedButton.styleFrom(
        backgroundColor: TropaColors.primaryOf(context),
        foregroundColor: TropaColors.onPrimaryOf(context),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      );

  /// Outlined page-header action, e.g. "Print Members".
  static ButtonStyle secondaryAction(BuildContext context) {
    final primary = TropaColors.primaryOf(context);
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      backgroundColor: primary.withValues(alpha: 0.06),
      side: BorderSide(color: primary.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  /// Text style for filter-bar fields and their dropdown items.
  static TextStyle fieldText(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        color: TropaColors.textHigh(context),
      );

  /// Decoration for dialog/form fields; pair with a label above via `LabeledField`.
  static InputDecoration formField(BuildContext context, {String? hint, IconData? icon, Widget? suffix, String? helper}) {
    final border = TropaColors.borderOf(context);
    final subtext = TropaColors.textMedium(context);
    final error = TropaColors.errorOf(context);
    OutlineInputBorder outline(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtext.withValues(alpha: 0.75)),
      helperText: helper,
      helperStyle: GoogleFonts.inter(fontSize: 11, color: subtext),
      helperMaxLines: 2,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: subtext) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: TropaColors.fieldFillOf(context),
      contentPadding: EdgeInsets.fromLTRB(icon != null ? 0 : 14, 13, 12, 13),
      border: outline(border),
      enabledBorder: outline(border),
      disabledBorder: outline(border.withValues(alpha: 0.5)),
      focusedBorder: outline(TropaColors.primaryOf(context), 1.5),
      errorBorder: outline(error, 1.5),
      focusedErrorBorder: outline(error, 2),
      errorStyle: GoogleFonts.inter(fontSize: 11, color: error),
    );
  }

  /// Decoration for search boxes and filter dropdowns above lists and tables.
  static InputDecoration filterField(BuildContext context, {String? hint, bool search = false}) {
    final border = TropaColors.borderOf(context);
    final subtext = TropaColors.textMedium(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtext.withValues(alpha: 0.75)),
      prefixIcon: search ? Icon(Icons.search, size: 18, color: subtext) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
      isDense: true,
      filled: true,
      fillColor: TropaColors.fieldFillOf(context),
      contentPadding: EdgeInsets.fromLTRB(search ? 0 : 14, 13, 10, 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: TropaColors.primaryOf(context), width: 1.5),
      ),
    );
  }
}

/// Width breakpoints shared by the shell and the pages: phone, tablet, desktop.
class TropaBreakpoints {
  static const double compact = 600;
  static const double expanded = 1024;

  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= expanded;
}

extension TropaScreen on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompactScreen => TropaBreakpoints.isCompact(screenWidth);
}
