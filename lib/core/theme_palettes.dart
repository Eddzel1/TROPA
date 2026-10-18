import 'package:flutter/material.dart';
import 'design_system.dart';

/// One selectable app theme. `TropaTheme.of` turns it into a ThemeData; component shapes and type
/// stay the same across palettes, only the colours change.
class TropaPalette {
  const TropaPalette({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.text,
    required this.muted,
    required this.border,
    required this.accentText,
    this.brand,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color background;     // scaffold
  final Color surface;        // cards, dialogs, menus, sidebar
  final Color surfaceVariant; // chips, icon tiles, table headers
  final Color primary;        // buttons, highlights
  final Color onPrimary;
  final Color secondary;      // badges, accents
  final Color onSecondary;
  final Color text;
  final Color muted;          // secondary text
  final Color border;
  final Color accentText;     // accent-coloured text that stays readable on surface
  final TropaBrand? brand;    // solid-colour sidebar; only the TROPA palette has one

  static const defaultId = 'tropa';
}

/// TROPA first (the default), then t1..t18 in the order of the source list (Set 1, 2, 3). t10 was
/// dropped: it had the same colours as t12. Ids stay fixed because they are saved per device.
const tropaPalettes = <TropaPalette>[
  TropaPalette(id: 'tropa', name: 'TROPA', brightness: Brightness.light,
      background: Color(0xFFFFFFFF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF1F5F9),
      primary: TropaColors.tropaBlue, onPrimary: TropaColors.tropaWhite, secondary: TropaColors.tropaGreen, onSecondary: TropaColors.tropaWhite,
      text: Color(0xDE000000), muted: Color(0x99000000), border: Color(0xFFE2E8F0), accentText: TropaColors.tropaGreen,
      brand: TropaBrand(
        sidebarBg: TropaColors.tropaBlue,
        sidebarFg: TropaColors.tropaWhite,
        sidebarFgMuted: Color(0xB3FFFFFF), // 70% White
        sidebarActiveBg: TropaColors.tropaWhite,
        sidebarActiveFg: TropaColors.tropaBlue,
      )),

  // ---- Set 1 ----
  TropaPalette(id: 't1', name: 'Ultra Violet + Plasma Yellow', brightness: Brightness.light,
      background: Color(0xFFF8F2FF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF2E6FF),
      primary: Color(0xFF7A00FF), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFFFE600), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF5E6070), border: Color(0xFFE7D1FF), accentText: Color(0xFF7A00FF)),
  TropaPalette(id: 't2', name: 'Electric Purple + Signal Cyan', brightness: Brightness.light,
      background: Color(0xFFF8F5FF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF0EBFF),
      primary: Color(0xFF6D35FF), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFF5DD8FF), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF5E6070), border: Color(0xFFE5DBFF), accentText: Color(0xFF6D35FF)),
  TropaPalette(id: 't3', name: 'Signal Red + Dusty Rose', brightness: Brightness.light,
      background: Color(0xFFF9DEDF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF9D2D5),
      primary: Color(0xFFFF173D), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFFABAC2), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFFAC2C8), accentText: Color(0xFF121318)),
  TropaPalette(id: 't4', name: 'Hacker Green + Black Cherry', brightness: Brightness.dark,
      background: Color(0xFF2A0011), surface: Color(0xFF391222), surfaceVariant: Color(0xFF441F2E),
      primary: Color(0xFF00FF66), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFF00FF66), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFF4F4F6), muted: Color(0xFFA7979F), border: Color(0xFF4C2937), accentText: Color(0xFF00FF66)),
  TropaPalette(id: 't5', name: 'Clay Orange + Warm Ivory', brightness: Brightness.light,
      background: Color(0xFFFFFCF4), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFFDF4EA),
      primary: Color(0xFFE26F4A), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFFAE3D5), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFFBE8DC), accentText: Color(0xFF121318)),
  TropaPalette(id: 't6', name: 'Blue Ribbon + Catskill White', brightness: Brightness.light,
      background: Color(0xFFF1F4F9), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFE4EBF9),
      primary: Color(0xFF1D61F3), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFCBDAF8), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFD3DFF8), accentText: Color(0xFF1D61F3)),

  // ---- Set 2 ----
  TropaPalette(id: 't7', name: 'Machine Red + Glacier Blue', brightness: Brightness.light,
      background: Color(0xFFDBF6FF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFDDEAF3),
      primary: Color(0xFFFF2E3A), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFE1D2DC), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFE0DAE3), accentText: Color(0xFF121318)),
  TropaPalette(id: 't8', name: 'Hyper Cobalt + Powder Sky', brightness: Brightness.light,
      background: Color(0xFFD6E3FF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFC9D9FF),
      primary: Color(0xFF0038FF), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFAFC4FF), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFB8CBFF), accentText: Color(0xFF0038FF)),
  TropaPalette(id: 't9', name: 'Dark Aubergine + Electric Pink', brightness: Brightness.dark,
      background: Color(0xFF2E0F35), surface: Color(0xFF3D2043), surfaceVariant: Color(0xFF472C4D),
      primary: Color(0xFFFF7FEC), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFFF7FEC), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFF4F4F6), muted: Color(0xFFA99DAD), border: Color(0xFF4F3555), accentText: Color(0xFFFF7FEC)),
  TropaPalette(id: 't11', name: 'Zero Black + Ghost Green', brightness: Brightness.dark,
      background: Color(0xFF050505), surface: Color(0xFF161616), surfaceVariant: Color(0xFF232323),
      primary: Color(0xFFD7FFE0), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFD7FFE0), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFD7FFE0), muted: Color(0xFF87A08D), border: Color(0xFF2D2D2D), accentText: Color(0xFFD7FFE0)),
  TropaPalette(id: 't12', name: 'Neon Orange + Charcoal', brightness: Brightness.dark,
      background: Color(0xFF111827), surface: Color(0xFF222836), surfaceVariant: Color(0xFF2E3441),
      primary: Color(0xFFFF9030), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFFF9030), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFF4F4F6), muted: Color(0xFF9EA0A7), border: Color(0xFF373D4A), accentText: Color(0xFFFF9030)),

  // ---- Set 3 ----
  TropaPalette(id: 't13', name: 'Royal Iris + Mint Frost', brightness: Brightness.light,
      background: Color(0xFFB7F7D4), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFB1EAD0),
      primary: Color(0xFF4C1D95), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFA4D0C9), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF4C1D95), muted: Color(0xFF8261B5), border: Color(0xFFA8D8CB), accentText: Color(0xFF4C1D95)),
  TropaPalette(id: 't14', name: 'Dark Olive + Fresh Lemon', brightness: Brightness.dark,
      background: Color(0xFF283113), surface: Color(0xFF373F24), surfaceVariant: Color(0xFF424A2F),
      primary: Color(0xFFF3FF74), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFF3FF74), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFF3FF74), muted: Color(0xFFA6B14F), border: Color(0xFF4A5239), accentText: Color(0xFFF3FF74)),
  TropaPalette(id: 't15', name: 'Nordic Indigo + Vanilla Mist', brightness: Brightness.light,
      background: Color(0xFFFFF4D6), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF2E9D3),
      primary: Color(0xFF263BAA), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFD8D3CE), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF121318), muted: Color(0xFF595A5D), border: Color(0xFFE1DAD0), accentText: Color(0xFF263BAA)),
  TropaPalette(id: 't16', name: 'Chrome Black + Digital Lilac', brightness: Brightness.dark,
      background: Color(0xFF0D0D0D), surface: Color(0xFF1E1E1E), surfaceVariant: Color(0xFF2A2A2A),
      primary: Color(0xFFD9B8FF), onPrimary: Color(0xFF0B0B0F), secondary: Color(0xFFD9B8FF), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFFF4F4F6), muted: Color(0xFF9C9C9D), border: Color(0xFF343434), accentText: Color(0xFFD9B8FF)),
  TropaPalette(id: 't17', name: 'Slate Ocean + Cloud Mint', brightness: Brightness.light,
      background: Color(0xFFDDFBEF), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFD3F0E6),
      primary: Color(0xFF2F4858), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFBEDBD4), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF2F4858), muted: Color(0xFF62737E), border: Color(0xFFC5E2DA), accentText: Color(0xFF2F4858)),
  TropaPalette(id: 't18', name: 'Ink Teal + Warm Sand', brightness: Brightness.light,
      background: Color(0xFFFFE2B8), surface: Color(0xFFFFFFFF), surfaceVariant: Color(0xFFF0D8B0),
      primary: Color(0xFF053D3A), onPrimary: Color(0xFFFFFFFF), secondary: Color(0xFFD2C4A1), onSecondary: Color(0xFF0B0B0F),
      text: Color(0xFF053D3A), muted: Color(0xFF507775), border: Color(0xFFDCCBA6), accentText: Color(0xFF053D3A)),
];

TropaPalette tropaPaletteById(String id) =>
    tropaPalettes.firstWhere((p) => p.id == id, orElse: () => tropaPalettes.first);
