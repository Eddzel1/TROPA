import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Design 2 Color Palette Specifications
/// Adheres strictly to MD2 Dark Theme & Light Theme Guidelines:
/// - Light Primary: #6200EE (Purple 500)
/// - Dark Primary:  #BB86FC (Purple 200, desaturated for WCAG AA)
/// - Primary Variant: #3700B3 (Purple 700)
/// - Secondary:     #03DAC6 (Teal 200)
/// - Secondary Variant: #018786 (Teal 700)
/// - Light Background & Surface: #FFFFFF
/// - Dark Background & Surface:  #121212 (Dark Grey for shadow depth & elevation overlays)
/// - Light Error:   #B00020
/// - Dark Error:    #CF6679 (Light Red with 40% white overlay)
/// - Text Hierarchy Opacities: 87% (High), 60% (Medium), 38% (Disabled)
class TropaColors {
  // MD2 Primary Palette
  static const primaryLight = Color(0xFF6200EE);       // Purple 500
  static const primaryDark = Color(0xFFBB86FC);        // Purple 200 (desaturated for dark mode)
  static const primaryVariant = Color(0xFF3700B3);     // Purple 700

  // MD2 Secondary Palette
  static const secondaryLight = Color(0xFF03DAC6);     // Teal 200
  static const secondaryDark = Color(0xFF03DAC6);      // Teal 200
  static const secondary = Color(0xFF03DAC6);          // Teal 200 (bright accent in both modes)
  static const secondaryVariant = Color(0xFF018786);   // Teal 700

  // MD2 Backgrounds
  static const lightBackground = Color(0xFFFFFFFF);    // White
  static const darkBackground = Color(0xFF121212);     // Dark Grey #121212

  // MD2 Base Surfaces
  static const lightSurface = Color(0xFFFFFFFF);       // White
  static const darkSurface = Color(0xFF121212);        // Dark Grey #121212

  // MD2 Dark Elevation Surfaces (White overlay on #121212)
  static const darkSurface0dp = Color(0xFF121212);     // 0dp (Base background, 0% overlay)
  static const darkSurface1dp = Color(0xFF1E1E1E);     // 1dp (5% overlay) - Cards & lists
  static const darkSurface2dp = Color(0xFF232323);     // 2dp (7% overlay) - Raised surfaces / inputs
  static const darkSurface4dp = Color(0xFF272727);     // 4dp (9% overlay) - App bars, search bars
  static const darkSurface8dp = Color(0xFF2E2E2E);     // 8dp (12% overlay) - Dialogs, menus
  static const darkSurface16dp = Color(0xFF363636);    // 16dp (15% overlay) - Modals, drawers
  static const darkSurface24dp = Color(0xFF383838);    // 24dp (16% overlay) - High elevation

  // Elevation aliases
  static const darkSurfaceLowest = darkSurface0dp;
  static const darkSurfaceLow = darkSurface1dp;
  static const darkSurfaceHigh = darkSurface2dp;
  static const darkSurfaceHighest = darkSurface4dp;
  static const darkSurfaceBright = darkSurface8dp;

  // MD2 Light Elevation & Surfaces
  static const lightSurfaceLow = Color(0xFFF5F5F5);    // 1dp surface / inputs
  static const lightSurfaceHigh = Color(0xFFEEEEEE);   // 2dp
  static const lightSurfaceHighest = Color(0xFFE0E0E0);// Borders & dividers

  // MD2 Typography Opacity Hierarchy
  // Dark text on Light surface:
  static const lightOnSurface = Color(0xDE000000);        // 87% Opacity (High emphasis)
  static const lightOnSurfaceVariant = Color(0x99000000); // 60% Opacity (Medium emphasis / Hints)
  static const lightOutline = Color(0x61000000);          // 38% Opacity (Disabled / Outline)

  // Light text on Dark surface:
  static const darkOnSurface = Color(0xDEFFFFFF);         // 87% Opacity (High emphasis)
  static const darkOnSurfaceVariant = Color(0x99FFFFFF);  // 60% Opacity (Medium emphasis / Hints)
  static const darkOutline = Color(0x61FFFFFF);           // 38% Opacity (Disabled / Outline)
  static const darkOutlineVariant = Color(0x1FFFFFFF);    // 12% Opacity (Subtle border)

  // MD2 "On" Colors
  static const onPrimaryLight = Color(0xFFFFFFFF);     // White
  static const onPrimaryDark = Color(0xFF000000);      // Black (high contrast on #BB86FC)
  static const onSecondary = Color(0xFF000000);        // Black in both modes
  static const onBackgroundLight = Color(0xDE000000);  // 87% Black
  static const onBackgroundDark = Color(0xDEFFFFFF);   // 87% White
  static const onSurfaceLight = Color(0xDE000000);     // 87% Black
  static const onSurfaceDark = Color(0xDEFFFFFF);      // 87% White

  // MD2 Error Palette
  static const errorLight = Color(0xFFB00020);         // Dark Red
  static const errorDark = Color(0xFFCF6679);          // Light Red (40% white overlay)
  static const onErrorLight = Color(0xFFFFFFFF);       // White
  static const onErrorDark = Color(0xFF000000);        // Black

  // TROPA brand palette (used by the TROPA theme)
  static const tropaBlue = Color(0xFF1F4DAA);
  static const tropaBlueDark = Color(0xFF173B85);     // Containers / pressed states
  static const tropaGreen = Color(0xFF60B358);
  static const tropaWhite = Color(0xFFFFFFFF);

  // Status
  static const offline = Color(0xFFF5A623);           // Amber: working offline, changes queued

  // Compatibility defaults
  static const primary = primaryDark;
  static const onPrimary = onPrimaryDark;
  static const error = errorDark;
  static const errorContainer = Color(0xFFCF6679);
  static const tertiary = secondary;
  static const tertiaryContainer = secondaryVariant;

  // Theme-aware helper methods
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;

  static Color onPrimaryOf(BuildContext context) => Theme.of(context).colorScheme.onPrimary;

  /// Accent color: teal in Dark/Light, green in the TROPA theme.
  static Color secondaryOf(BuildContext context) => Theme.of(context).colorScheme.secondary;

  /// Higher-contrast accent for text/icons on light surfaces.
  static Color secondaryStrongOf(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.extension<TropaBrand>() != null) return theme.colorScheme.secondary;
    return theme.brightness == Brightness.dark ? secondary : secondaryVariant;
  }

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;

  static Color surfaceOf(BuildContext context, [int dp = 1]) {
    if (Theme.of(context).brightness == Brightness.light) {
      return dp == 0 ? lightBackground : (dp <= 1 ? lightSurface : lightSurfaceLow);
    }
    switch (dp) {
      case 0: return darkSurface0dp;
      case 1: return darkSurface1dp;
      case 2: return darkSurface2dp;
      case 4: return darkSurface4dp;
      case 8: return darkSurface8dp;
      case 16: return darkSurface16dp;
      case 24: return darkSurface24dp;
      default: return darkSurface1dp;
    }
  }

  static Color textHigh(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnSurface : lightOnSurface;

  static Color textMedium(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOnSurfaceVariant : lightOnSurfaceVariant;

  static Color textDisabled(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOutline : lightOutline;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkOutlineVariant : lightSurfaceHighest;

  static Color errorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorDark : errorLight;

  static Color onErrorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? onErrorDark : onErrorLight;
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

  static ThemeData get darkTheme => _withTypography(_darkBase);
  static ThemeData get lightTheme => _withTypography(_lightBase);

  static ThemeData get _darkBase {
    final baseTextTheme = Typography.material2021().white;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TropaColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: TropaColors.primaryDark,                    // #BB86FC (Purple 200)
        onPrimary: TropaColors.onPrimaryDark,                // #000000 (Black)
        primaryContainer: TropaColors.primaryVariant,        // #3700B3 (Purple 700)
        onPrimaryContainer: Colors.white,
        secondary: TropaColors.secondary,                    // #03DAC6 (Teal 200)
        onSecondary: TropaColors.onSecondary,                // #000000 (Black)
        secondaryContainer: TropaColors.secondaryVariant,    // #018786 (Teal 700)
        onSecondaryContainer: Colors.white,
        surface: TropaColors.darkSurface1dp,                 // #1E1E1E (1dp elevation)
        onSurface: TropaColors.darkOnSurface,                // 87% White
        onSurfaceVariant: TropaColors.darkOnSurfaceVariant,  // 60% White
        outline: TropaColors.darkOutline,                    // 38% White
        outlineVariant: TropaColors.darkOutlineVariant,      // 12% White
        error: TropaColors.errorDark,                        // #CF6679
        onError: TropaColors.onErrorDark,                    // #000000
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TropaColors.darkSurface8dp,         // #2E2E2E (8dp dialog elevation)
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: TropaColors.darkSurface1dp,                   // #1E1E1E (1dp)
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TropaColors.darkOutlineVariant, width: 1),
        ),
      ),
      dividerColor: TropaColors.darkOutlineVariant,          // 12% White
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TropaColors.darkSurface2dp,               // #232323 (2dp)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.darkOutlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.darkOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.primaryDark, width: 2), // #BB86FC
        ),
        labelStyle: const TextStyle(color: TropaColors.darkOnSurfaceVariant),
        hintStyle: const TextStyle(color: TropaColors.darkOutline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TropaColors.primaryDark,
          foregroundColor: TropaColors.onPrimaryDark,
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
            return TropaColors.primaryDark;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(TropaColors.onPrimaryDark),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.primaryDark;
          }
          return TropaColors.darkOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.primaryDark.withValues(alpha: 0.5);
          }
          return TropaColors.darkSurface4dp;
        }),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: TropaColors.darkOnSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TropaColors.darkOnSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TropaColors.darkOnSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: TropaColors.darkOnSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: TropaColors.darkOnSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: TropaColors.darkOutline,
        ),
      ),
    );
  }

  static ThemeData get _lightBase {
    final baseTextTheme = Typography.material2021().black;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: TropaColors.lightBackground, // #FFFFFF
      colorScheme: const ColorScheme.light(
        primary: TropaColors.primaryLight,                   // #6200EE (Purple 500)
        onPrimary: TropaColors.onPrimaryLight,               // #FFFFFF (White)
        primaryContainer: TropaColors.primaryVariant,        // #3700B3 (Purple 700)
        onPrimaryContainer: Colors.white,
        secondary: TropaColors.secondary,                    // #03DAC6 (Teal 200)
        onSecondary: TropaColors.onSecondary,                // #000000 (Black)
        secondaryContainer: TropaColors.secondaryVariant,    // #018786
        onSecondaryContainer: Colors.white,
        surface: TropaColors.lightSurface,                   // #FFFFFF (White)
        onSurface: TropaColors.lightOnSurface,               // 87% Black
        onSurfaceVariant: TropaColors.lightOnSurfaceVariant, // 60% Black
        outline: TropaColors.lightOutline,                   // 38% Black
        outlineVariant: TropaColors.lightSurfaceHighest,     // #E0E0E0
        error: TropaColors.errorLight,                       // #B00020
        onError: TropaColors.onErrorLight,                   // #FFFFFF
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TropaColors.lightSurface,           // #FFFFFF
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        color: TropaColors.lightSurface,                     // #FFFFFF
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: TropaColors.lightSurfaceHighest, width: 1), // #E0E0E0
        ),
      ),
      dividerColor: TropaColors.lightSurfaceHighest,         // #E0E0E0
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TropaColors.lightSurfaceLow,              // #F5F5F5
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.lightSurfaceHighest),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.lightSurfaceHighest),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.primaryLight, width: 2), // #6200EE
        ),
        labelStyle: const TextStyle(color: TropaColors.lightOnSurfaceVariant),
        hintStyle: const TextStyle(color: TropaColors.lightOutline),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TropaColors.primaryLight,
          foregroundColor: TropaColors.onPrimaryLight,
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
            return TropaColors.primaryLight;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(TropaColors.onPrimaryLight),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.primaryLight;
          }
          return TropaColors.lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.primaryLight.withValues(alpha: 0.5);
          }
          return TropaColors.lightSurfaceHigh;
        }),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
        headlineLarge: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: TropaColors.lightOnSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TropaColors.lightOnSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TropaColors.lightOnSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          color: TropaColors.lightOnSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: TropaColors.lightOnSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: TropaColors.lightOutline,
        ),
      ),
    );
  }

  /// TROPA brand theme: white surfaces, blue primary, green accents, blue sidebar.
  static ThemeData get tropaTheme {
    final base = lightTheme;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: TropaColors.tropaBlue,
        onPrimary: TropaColors.tropaWhite,
        primaryContainer: TropaColors.tropaBlueDark,
        onPrimaryContainer: TropaColors.tropaWhite,
        secondary: TropaColors.tropaGreen,
        onSecondary: TropaColors.tropaWhite,
        secondaryContainer: TropaColors.tropaGreen,
        onSecondaryContainer: TropaColors.tropaWhite,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: TropaColors.tropaBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TropaColors.tropaBlue,
          foregroundColor: TropaColors.tropaWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.tropaBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(TropaColors.tropaWhite),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.tropaBlue;
          }
          return TropaColors.lightOutline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TropaColors.tropaBlue.withValues(alpha: 0.5);
          }
          return TropaColors.lightSurfaceHigh;
        }),
      ),
      extensions: const [
        TropaBrand(
          sidebarBg: TropaColors.tropaBlue,
          sidebarFg: TropaColors.tropaWhite,
          sidebarFgMuted: Color(0xB3FFFFFF), // 70% White
          sidebarActiveBg: TropaColors.tropaWhite,
          sidebarActiveFg: TropaColors.tropaBlue,
        ),
      ],
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
        color: Theme.of(context).brightness == Brightness.dark ? TropaColors.darkOnSurface : TropaColors.lightOnSurface,
      );

  /// Decoration for dialog/form fields; pair with a label above via `LabeledField`.
  static InputDecoration formField(BuildContext context, {String? hint, IconData? icon, Widget? suffix, String? helper}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? TropaColors.darkOutlineVariant : TropaColors.lightSurfaceHighest;
    final subtext = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
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
      fillColor: isDark ? TropaColors.darkSurface : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? TropaColors.darkOutlineVariant : const Color(0xFFE2E8F0);
    final subtext = isDark ? TropaColors.darkOnSurfaceVariant : TropaColors.lightOnSurfaceVariant;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: subtext.withValues(alpha: 0.75)),
      prefixIcon: search ? Icon(Icons.search, size: 18, color: subtext) : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
      isDense: true,
      filled: true,
      fillColor: isDark ? TropaColors.darkSurface : Colors.white,
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
