---
name: Civic Horizon
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#bdc8d1'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#87929a'
  outline-variant: '#3e484f'
  surface-tint: '#7bd0ff'
  primary: '#8ed5ff'
  on-primary: '#00354a'
  primary-container: '#38bdf8'
  on-primary-container: '#004965'
  inverse-primary: '#00668a'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffc174'
  on-tertiary: '#472a00'
  tertiary-container: '#f59e0b'
  on-tertiary-container: '#613b00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c4e7ff'
  primary-fixed-dim: '#7bd0ff'
  on-primary-fixed: '#001e2c'
  on-primary-fixed-variant: '#004c69'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  headline-xl:
    fontFamily: Manrope
    fontSize: 2.25rem
    fontWeight: '700'
    lineHeight: 2.75rem
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Manrope
    fontSize: 1.75rem
    fontWeight: '700'
    lineHeight: 2.25rem
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Manrope
    fontSize: 1.5rem
    fontWeight: '600'
    lineHeight: 2rem
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Manrope
    fontSize: 1.25rem
    fontWeight: '600'
    lineHeight: 1.75rem
  body-lg:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: '400'
    lineHeight: 1.5rem
  body-md:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '400'
    lineHeight: 1.25rem
  body-sm:
    fontFamily: Inter
    fontSize: 0.75rem
    fontWeight: '400'
    lineHeight: 1rem
  label-lg:
    fontFamily: Inter
    fontSize: 0.875rem
    fontWeight: '500'
    lineHeight: 1.25rem
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 0.75rem
    fontWeight: '500'
    lineHeight: 1rem
    letterSpacing: 0.02em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 0.6875rem
    fontWeight: '400'
    lineHeight: 0.875rem
    letterSpacing: 0.04em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 0.75rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system is engineered for enterprise community governance, cooperative financial stewardship, and mutual-aid operations. The aesthetic blends Corporate Modern reliability with precision Material 3 spatial logic, projecting institutional trust, operational transparency, and dignified social utility.

The emotional signature is steady, analytical, and respectful: users must feel absolute certainty when auditing ledgers, distributing aid allocations, or tracking territorial community clusters. Visual clutter is eliminated in favor of high-legibility density, deliberate information hierarchy, and calm authoritative surfaces that keep administrative cognitive load minimal during high-volume operations.

## Colors

The palette operates in a dark slate environment built for intensive operational longevity and reduced display fatigue.

- **Primary (`#38BDF8` - Electric Azure):** Used for focal interactive targets, critical system navigation, selected geospatial polygon boundaries, and primary transaction flows.
- **Secondary (`#10B981` - Muted Emerald):** Represents operational stability, reconciled balance ledgers, active beneficiary status, and verified contributions.
- **Tertiary (`#F59E0B` - Deep Amber):** Signals unverified identities, queued distribution batches, review-required disbursements, and conditional validations.
- **Alert / Overdue (`#EF4444` - Controlled Crimson):** Reserved strictly for critical deficits, flagged records, overdue micro-loans, and territorial alerts.
- **Neutral Canvas (`#0F172A` to `#1E293B`):** Dark navy-slate base surfaces that anchor information layers, providing contrast against luminous metric data without harsh pure-black cutoffs.

## Typography

The typography architecture uses a three-tier engine:
- **Manrope** provides authoritative geometric structure for headlines, operational dashboards, and modal summaries.
- **Inter** ensures uninterrupted neutral readability across multi-column data views, descriptive fields, and system audit logs.
- **JetBrains Mono** anchors currency values, transaction hashes, geospatial coordinates, member identification codes, and metric delta indicators, ensuring alignment across tabular displays.

Letter tracking on uppercase code tags and tabular badges is slightly relaxed for immediate scanning against deep background layers.

## Layout & Spacing

The layout is built on a responsive 12-column fluid grid tailored for data-dense desktop dashboards and cooperative control panels.

- **Desktop (1280px+):** 12 columns, 1.5rem (`24px`) gutters, 2rem margins. Accommodates persistent left navigation, split geospatial views, and side-by-side transaction ledgers.
- **Tablet (768px - 1279px):** 8 columns, 1rem gutters, 1.5rem margins. Primary panels collapse auxiliary sidebars into slide-over drawers; KPI rows adapt to 2x2 grids.
- **Mobile (< 768px):** 4 columns, 0.75rem gutters, 1rem margins. Full horizontal reflow; complex tables shift to stacked card lists with horizontal scroll tokens for immutable data lines.

## Elevation & Depth

Visual hierarchy uses Material 3 tonal layering over physical drop shadows. Elevated elements gain luminance through higher-tier surface values rather than intense drop shadows:

- **Level 0 (Base Canvas):** `#0F172A` — Underlay screen backdrop.
- **Level 1 (Structural Cards & Sidebars):** `#1E293B` — Surface container with a subtle 1px border (`#334155`).
- **Level 2 (Active Controls, Hover States & Popovers):** `#334155` with ambient feathering: `0px 4px 16px -2px rgba(0, 0, 0, 0.45)`.
- **Level 3 (Modals & Emergency Drawers):** `#1E293B` bordered by `#475569`, backed by a dark frosted scrim (`rgba(15, 23, 42, 0.8)` with an 8px blur) and `0px 12px 32px -4px rgba(0, 0, 0, 0.6)`.

Interactive maps feature inset boundary shadows to simulate physical recessed cartography, with selected administrative zones illuminated via an outer glow tinted with the primary hue (`rgba(56, 189, 248, 0.25)`).

## Shapes

The system relies on compact, structured shapes (`roundedness: 1` — 0.25rem / 4px base, scaling to 8px on master cards and 12px on system dialogs).

This restrained edge profile reinforces an industrial, technical discipline suitable for balance sheets, legal records, and civic inventories. Pills and circular shapes are restricted strictly to micro status pips, system avatar tags, and map point clusters.

## Components

### Buttons
- **Primary:** Solid `#38BDF8` background with dark `#0F172A` semibold text. Focus ring: 2px offset in `#38BDF8`.
- **Secondary:** Surface `#1E293B` with border `#334155` and text `#F8FAFC`. Hover brings background to `#334155`.
- **Destructive:** Subtle crimson base tint (`rgba(239, 68, 68, 0.15)`) with crimson text and border `#EF4444`. Solid crimson on confirm action.

### KPI Metric Tiles
Cards set to Level 1 elevation with a 1px border (`#334155`). Feature a mono-spaced delta indicator (`+12.4%`) paired with secondary emerald or alert crimson backgrounds. The main metric is rendered in bold Manrope typography.

### Data Tables
High-contrast dense presentation. Header row uses subtle slate underlay `#1E293B` with uppercase `label-md` mono text in `#94A3B8`. Alternate row striping is omitted; clean 1px row separators in `#334155` define borders. Cells containing financial figures or dates align right using monospaced numerals.

### Status Chips
Compact pill badges with a dark tinted fill and matching border:
- **Active / Paid:** Background `rgba(16, 185, 129, 0.12)`, text `#34D399`, border `rgba(16, 185, 129, 0.3)`.
- **Pending / In-Review:** Background `rgba(245, 158, 11, 0.12)`, text `#FBBF24`, border `rgba(245, 158, 11, 0.3)`.
- **Alert / Overdue:** Background `rgba(239, 68, 68, 0.12)`, text `#F87171`, border `rgba(239, 68, 68, 0.3)`.

### Form Fields & Checkboxes
Inputs sit on base `#0F172A` with a 1px `#334155` border. Focus transitions to an electric primary glow (`#38BDF8`). Checkboxes use crisp 4px corner radii, filling solid primary with dark check glyphs when active.

### Geospatial Control Overlays
Floating map panels use Level 2 elevation with semi-translucent slate backdrops (`rgba(30, 41, 59, 0.92)` + `backdrop-filter: blur(8px)`). Territory filter legends and layer toggles use compact typography and tight 8px internal padding.