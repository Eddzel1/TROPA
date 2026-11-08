# TROPA Design System

This is the reference for how TROPA looks and behaves. It describes the code as it is: the source
of truth is `lib/core/design_system.dart` (colours, type, field styles, breakpoints),
`lib/core/theme_palettes.dart` (themes), `lib/core/motion.dart` (motion and timing) and
`lib/widgets/form_fields.dart` (shared form pieces).

**Keep this file current.** Any change to colours, type, spacing, components, motion or interaction
patterns updates this document in the same change.

## Principles

1. **Calm, readable admin tool.** Officers scan many records at once, so screens are dense but
   quiet. Colour carries meaning (status, urgency), never decoration.
2. **One system, many themes.** Screens read colours through `TropaColors.*Of(context)` helpers,
   never fixed values. Shapes, type and spacing stay the same across every palette; only colours
   change.
3. **Readable by default.** Accent and secondary text colours are adjusted until they reach WCAG AA
   (4.5:1) on their surface. Text on a status colour uses `TropaColors.onColor(background)`.
4. **Matches the paper records.** Names, places and reference numbers are typed and stored in
   CAPITALS (`UpperCaseFormatter` + `TextCapitalization.characters`). Dates and times are Philippine
   time (GMT+8, `formatPh`), and money is pesos (`₱1,234.00`).
5. **Works offline.** Everything saves to the device first and syncs later. The sync pill in the
   header always shows the state.
6. **Permissions shape the screen.** Controls the user can't use are hidden rather than disabled.
7. **Phone, tablet and desktop.** Every layout adapts at the two breakpoints below.

## Typography

Manrope is used only for titles and big numbers; everything else is Inter. Styles live in
`TropaText`.

| Style | Font | Size / weight | Use |
|---|---|---|---|
| `pageTitle` | Manrope | 24 / 800 | Page titles |
| `dialogTitle` | Manrope | 18 / 700 | Dialog and panel titles |
| `kpi` | Manrope | 18–24 / 800, letter-spacing −0.5 | Totals, stat tiles |
| `sectionTitle` | Inter | 14 / 700 | Card and section titles |
| `sectionHeader` | Inter | 12.5 / 600 | Form section above a divider |
| `body` / `bodyStrong` | Inter | 13 / 400, 600 | Body text, field text, list titles |
| `meta` | Inter | 12, tabular figures | Table cells, IDs, dates, amounts |
| `caption` | Inter | 11.5 | Help text, subtitles |
| `fieldLabel` | Inter | 11.5 / 500 | Label above a field |
| `tableHeader` | Inter | 11 / 700, spacing 0.5, caps | Table headers |
| `badge` | Inter | 11 / 600, spacing 0.3 | Pills and badges |
| `groupLabel` | Inter | 10.5 / 600, spacing 0.8, caps | "LOCATION", sidebar groups |
| `action` | Inter | 12.5 / 600 | Text buttons inside cards and dialogs |

Numbers that line up in columns (amounts, counts, IDs) use tabular figures.

## Colour

### Default theme (TROPA, light)

| Role | Value | Used for |
|---|---|---|
| Primary | TROPA Blue `#1F4DAA` | Primary buttons, focus outlines, selected tabs, sidebar |
| Accent | TROPA Green `#60B358` | Success, "up to date", money collected |
| Background / cards | `#FFFFFF` | Page and card surfaces |
| Chip / table header | `#F1F5F9` | Chips, icon tiles, table headers |
| Border | `#E2E8F0` | All 1px borders and dividers |
| Text | black 87% / 60% / 38% | Main / secondary / disabled and hints |

Users pick other palettes per device in Settings › Appearance (`t1`–`t18`; five are dark). Every
palette fills the same 13 slots, so components never need per-theme code. Only the TROPA palette
paints the sidebar solid blue (`TropaBrand`).

### Status colours (the same in every theme)

| Colour | Value | Meaning |
|---|---|---|
| Amber | `#F5A623` (`TropaColors.offline`) | Warning, offline, waiting 3+ days, 6+ months unpaid |
| Red | `#B00020` light / `#CF6679` dark (`errorOf`) | Errors, overdue (7+ days, 12+ months unpaid), void, delete |
| Teal | `#03DAC6` / `#018786` | Inactive map pins, NEW badges |

**Status pattern:** a 10–12% tint of the colour as the background, with the full colour for text
or icon (`TropaBadge`, day-count pills, unpaid amounts). Amounts and counts stay neutral until they
cross a threshold; don't paint every number red.

Shadows may use black at low alpha. Any other fixed colour in screen code is a bug. Printed outputs
(PDF sheets, the ID card) and the startup screen are exempt.

## Layout

| Width | Name | Navigation |
|---|---|---|
| < 600 | Phone (`isCompact`) | Drawer opened from ☰; header 56px |
| 600–1023 | Tablet | 76px icon rail |
| ≥ 1024 | Desktop (`isExpanded`) | 270px sidebar, collapsible to the rail (button at the bottom of the sidebar, saved per device) |

- Page padding is 24px (16px on phones). `TropaPageHeader` puts the title on the left and actions on
  the right; below 700px the actions wrap under the title.
- List and detail screens use a list on the left and a detail panel on the right from about 860px;
  narrower, the detail opens as a dialog.
- Tables become compact cards on narrow widths.
- Form rows use `ResponsiveFieldRow`, which stacks fields vertically on phones.

## Shape and elevation

| Element | Radius | Notes |
|---|---|---|
| Buttons, fields, dropdowns, segmented buttons | 8 | |
| Cards | 10 | 1px border, elevation 1 |
| Surfaces / panels | 12–14 | 1px border, no shadow |
| Dialogs | 16 | Elevation 8 |
| Badges and pills | 10–20 | |

## Components

### Text fields

- The label goes **above** the field, never inside it: `LabeledField` + `TropaStyles.formField`.
  The label uses `fieldLabel`, muted, with a 6px gap.
- Fields are dense with 13px padding, 8px corners, the field fill colour and a 1px border.
  - Focused: primary border at 1.5px.
  - Error: red border at 1.5px (2px when focused), with an 11px message underneath.
- Optional extras: an 18px prefix icon and up to two lines of helper text.
- Name, place and reference fields use `UpperCaseFormatter`.

### Dropdowns

- Use `DropdownButtonFormField` with `TropaStyles.filterField` (filter bars) or `formField` (forms),
  `TropaStyles.fieldText` for the text, and **always** `icon: TropaStyles.dropdownIcon(context)`
  (an 18px ⌄ chevron in muted text). The settings theme picker is the only exception, because it
  previews each palette's colours.
- Options are 13px Inter on the card colour, cut off with "…" when too long.
- An empty choice is a real option: "All barangays" in filters, "Choose purok" where a choice is
  required.
- Location pickers cascade LGU → Barangay → Purok. Changing one resets the ones after it. A sole
  option is picked automatically, and the lists only offer places within the user's scope.

### Filters and search

- Search boxes use `TropaStyles.filterField(search: true)`: a magnifier icon and a hint that says
  what can be searched. They run `TropaMotion.searchDebounce` (300ms) after the last keystroke.
  (The member form's duplicate-person check waits 500ms, because it does a heavier lookup.)
- Filter bars put search first, then dropdowns: one row on desktop, stacked on narrow screens.
- Quick choices are `ChoiceChip`s (date presets: Today, This week, This month, Custom…), and
  toggles are `FilterChip`s ("Unpaid only").
- Filters drive everything on the screen: totals, counts and the pager follow them. Changing a
  filter returns to page 1 and closes any open detail.
- Empty results explain themselves ("Nothing matches these filters").

### Buttons

- **Filled primary:** the one main action on a page or dialog. Page-header actions use
  `TropaStyles.primaryAction`.
- **Outlined:** secondary page actions, with a 6% primary tint and a 30% primary border
  (`TropaStyles.secondaryAction`).
- **Text:** Cancel, Close and in-card actions.
- **Destructive actions** go behind a ⋯ menu or a confirmation (`confirmAction`), in red. Prefer
  Void (with a reason) over Delete wherever there is an audit trail.

### Badges, lists and tables

- `TropaBadge` gives small tinted pills for statuses and tags (TROPA MEMBER, VOTER, VOID, NEW).
- In lists, clicking a row opens the record. Row actions sit in a ⋯ menu or as small icon buttons
  on wide screens.
- Table headers use `tableHeader` on the chip colour. Amounts are right-aligned with tabular
  figures; secondary detail sits under the main value as a caption.

### Feedback

- Snackbars confirm saves ("Moved to …", "Receipt voided").
- Loading shows a centred spinner. An empty screen shows an icon, a title and a one-line hint.
- The sync pill shows Synced, Syncing, Offline, Upload failing or Local only, and opens the sync
  queue.

## Motion

Tokens are in `TropaMotion` (`lib/core/motion.dart`).

- Durations are 150 / 200 / 250ms; exits are 20% shorter than entrances. Entrances ease out, moves
  ease in-out, and nothing bounces.
- **Dialogs** (`showTropaDialog`): fade in while scaling up from 0.95 over 200ms, and close in 160ms.
- **Press feedback** (`TropaPressable`): scales to 0.97 on tappable items.
- **Staggered entrance** (`TropaStaggerIn`): items arrive 30ms apart, e.g. the dashboard KPI cards.
- **Success pulse** (`TropaSuccessPulse`): one pulse to confirm, e.g. the sync pill on catching up.
- **Never animate** page switches or the sidebar width. They re-lay out large tables and lag.
- Every animation is skipped when the OS "reduce motion" setting is on.
