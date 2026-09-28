---
name: Academic Utility Portal
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#404751'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#717882'
  outline-variant: '#c0c7d3'
  surface-tint: '#0062a2'
  primary: '#005994'
  on-primary: '#ffffff'
  primary-container: '#0072bc'
  on-primary-container: '#ecf3ff'
  inverse-primary: '#9dcaff'
  secondary: '#35618d'
  on-secondary: '#ffffff'
  secondary-container: '#a2cdff'
  on-secondary-container: '#2a5782'
  tertiary: '#923b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#ba4c00'
  on-tertiary-container: '#ffefe9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#9dcaff'
  on-primary-fixed: '#001d35'
  on-primary-fixed-variant: '#00497c'
  secondary-fixed: '#d1e4ff'
  secondary-fixed-dim: '#a0cafc'
  on-secondary-fixed: '#001d35'
  on-secondary-fixed-variant: '#184974'
  tertiary-fixed: '#ffdbcc'
  tertiary-fixed-dim: '#ffb693'
  on-tertiary-fixed: '#351000'
  on-tertiary-fixed-variant: '#7a3000'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  headline-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.375rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style
The design system powers an institutional attendance management portal designed for academic lecturers and university administrative staff. Rooted in utility, precision, and reliable enterprise performance, it emphasizes clarity over ornamentation. The primary operational objective is high-density data presentation without visual fatigue, enabling rapid visual scanning and high-speed data entry during or after lectures.

The interface adheres to an **Enterprise Utility / Modern Institutional** style:
- Structured, data-centric workspace built specifically around 1440x900 desktop viewports.
- Clear structural hierarchy governed by crisp containment, contrasting header panels, and consistent tabular grids.
- Respectful integration of institutional heritage through precise tertiary accent stripes, balanced by pragmatic data surfaces.
- Strictly low-latency visual feedback: immediate state indicators, crisp row striping, and unambiguous status signaling.

## Colors
The palette balances institutional identity with stringent enterprise usability and high contrast.

### Palette Architecture
- **Primary (`#0072BC`)**: The institutional core anchor, applied to top navigation bars, interactive buttons, focused states, and hyperlink actions.
- **Secondary (`#1F4E79`)**: A grounded dark academic navy, reserved for high-prominence table header rows, critical section banners, and dense information frame titles.
- **Tertiary Accent Striping**:
  - `#F36F21` (Academic Orange): Primary accent and brand ribbon lead.
  - `#0072BC` (Academic Blue): Middle band continuity.
  - `#6CB33F` (Academic Green): Grounding identity finish.
- **Neutral Canvas & Surfaces**:
  - Canvas / Page Background: `#F4F6F8` (reduces long-shift eye strain).
  - Card & Container Surfaces: Pure `#FFFFFF`.
  - Secondary Row / Container Tint: `#F8FAFC`.
  - Structural Borders: Subtle `#E2E8F0` and definition borders `#D1D5DB`.
  - Breadcrumb Strip Surface: `#EBF3FA`.

### Status Semantics
- **Present / Attended**: `#2E9E4F` (solid, crisp legibility).
- **Absent / Critical Alert**: `#D93025`.
- **Pending / Attention**: `#F5A623`.
- **In-Progress / Current Slot**: `#0284C7`.
- **Future / Inactive / Excused**: `#9AA0A6`.

## Typography
Built using **Inter** to ensure maximum legibility at small sizes, dense tabular alignment, and structured data layouts.

- **Page Titles (`headline-lg`)**: 20px / 600 weight provides immediate workspace context without consuming excessive vertical space.
- **Section & Modal Headers (`headline-md`)**: 16px / 600 weight organizes panel segments.
- **Standard Body & Table Cells (`body-md`)**: 14px / 400 weight acts as the default reading scale for records, student IDs, and slot details.
- **Data Attributes & Secondary Labels (`label-md`)**: 12px / 500 weight handles status tags, table metadata, form helpers, and audit timestamps.
- **Dense Compact Identifiers (`label-sm`)**: 11px uppercase used for badge tickers and micro-column keys.
- **Tabular Figures**: Tabular numbers (`font-variant-numeric: tabular-nums`) must be active across all table matrices to keep grades, dates, student counts, and percentages cleanly aligned.

## Layout & Spacing
The layout model is tailored for 1440x900 enterprise desktop displays, emphasizing vertical compactness and wide-canvas utility.

- **Global Shell**:
  - Accent Ribbon: Top 4px segmented tricolor bar (`#F36F21`, `#0072BC`, `#6CB33F`).
  - Primary Navigation: 48px height `#0072BC` navigation bar.
  - Sub-navigation & Breadcrumbs: 32px height `#EBF3FA` full-width strip.
  - Page Container: Fixed max-width layout of 1400px with 20px (`1.25rem`) side margins to maintain structured ergonomics.
- **Grid Structure**:
  - 12-column layout with 16px (`1rem`) gutters for dashboard controls and filter matrices.
  - Workspaces switch between single full-width data panels (12 columns) and split viewports (3-column subject tree / 9-column attendance grid).
- **Rhythm & Compaction**:
  - Tight spatial scale (`space-xs` = 4px, `space-sm` = 6px, `space-md` = 12px) maximizes the number of rows visible above the fold without causing visual crowding.

## Elevation & Depth
Depth in this system is driven by structural borders and crisp surface contrast rather than diffused drop shadows, preserving an authentic academic utility portal feel:

- **Surface Tiers**:
  - `Level 0 (Base Canvas)`: `#F4F6F8` background.
  - `Level 1 (Data Cards & Workbenches)`: `#FFFFFF` surface framed by a solid `1px solid #E2E8F0` or `#D1D5DB` border.
  - `Level 2 (Headers & Filters)`: High-contrast header strips (`#1F4E79` or `#E2E8F0`) anchored directly flush against cards.
  - `Level 3 (Overlays & Dialogs)`: Modals and dropdown flyouts sit on `#FFFFFF` with a clean `1px solid #CBD5E1` border and a restrained shadow (`0 4px 12px rgba(15, 23, 42, 0.08)`).
- **Interactive Feedback**: Rather than floating or expanding, hovered table rows shift surface color to `#EDF2F7`, and focused interactive controls use an authoritative `2px` ring in `#0072BC`.

## Shapes
The design uses restrained 6px corner radii across all operational elements to preserve structured horizontal and vertical gridlines:

- **Cards, Filter Strips, and Panels**: Bound by strict 6px outer corners. Table headers feature top-left and top-right 6px curves, while the table body retains sharp internal grid lines.
- **Action Buttons, Form Controls, and Modals**: Uniform 6px corners.
- **Status Chips & Pills**: 4px to 6px subtle rounding; circular pills are explicitly avoided to preserve the institutional table aesthetic.
- **Table Data Grid**: Sharp internal 0px boundaries formed by `1px solid #E2E8F0` row and column dividers.

## Components

### 1. Global Shell & Navigation
- **Accent Strip**: 4px top edge ribbon split equally into FPT Orange (`#F36F21`), FPT Blue (`#0072BC`), and FPT Green (`#6CB33F`).
- **Main Bar**: `#0072BC` background, 48px height, white institutional typography, user switch dropdown, term selector, and semester switcher.
- **Breadcrumb Ribbon**: `#EBF3FA` background, 32px height, `1px solid #D8E2EC` bottom border, 12px link path with separator chevron.

### 2. Data Tables (Core Matrix)
- **Table Container**: Bordered card wrapper (`1px solid #D1D5DB`) with 6px border-radius.
- **Headers**:
  - Primary Dark Navy: Background `#1F4E79`, color `#FFFFFF`, 13px weight 600, uppercase letter-spacing 0.02em, 36px cell height, padding 8px 12px.
  - Secondary / Group Header: Background `#E2E8F0`, color `#1E293B`, 12px weight 600.
- **Zebra Striping**: Even rows `#FFFFFF`, odd rows `#F8FAFC`. Hovered rows `#EDF2F7`.
- **Borders**: Continuous `1px solid #E2E8F0` horizontal and vertical cell rules.
- **Cell Height**: Compact 36px to 40px default to display 15–20 student records without scrolling.

### 3. Attendance Status Chips & Toggles
- **Chip Construction**: 12px font, weight 600, 20px height, 6px border-radius, padding 2px 8px.
- **Variants**:
  - Present: Background `#E6F4EA`, Text `#1E7E34`, Border `1px solid #A8DAB5`.
  - Absent: Background `#FCE8E6`, Text `#D93025`, Border `1px solid #F5C2C7`.
  - Pending: Background `#FEF3D6`, Text `#B76E00`, Border `1px solid #FCD38D`.
  - In-Progress: Background `#E0F2FE`, Text `#0284C7`, Border `1px solid #BAE6FD`.
  - Future / Exempt: Background `#F1F3F4`, Text `#5F6368`, Border `1px solid #DADCE0`.
- **Attendance Rapid Toggle Group**: Segmented 3-button button group (P / A / E) within cells for high-speed single-click recording. Active state fills with the semantic status color and white text.

### 4. Buttons
- **Primary**: Background `#0072BC`, text `#FFFFFF`, border none, 32px height, 6px border-radius, 13px weight 600. Hover: `#005C99`. Active: `#004877`.
- **Secondary / Action Toolbars**: Background `#FFFFFF`, text `#1E293B`, border `1px solid #D1D5DB`. Hover: `#F8FAFC` and border `#94A3B8`.
- **Danger / Reset**: Background `#FFFFFF`, text `#D93025`, border `1px solid #D93025`. Hover: `#FCE8E6`.

### 5. Input Fields & Dropdowns
- **Form Controls**: Height 32px, 13px typography, border `1px solid #CBD5E1`, border-radius 6px, padding 0 8px.
- **Focus State**: Border color `#0072BC`, outline `2px solid rgba(0, 114, 188, 0.2)`.

### 6. Titled Panels & Cards
- **Card Panel**: Background `#FFFFFF`, border `1px solid #D1D5DB`, border-radius 6px.
- **Panel Header Strip**: Height 36px, background `#F1F5F9`, border-bottom `1px solid #CBD5E1`, typography 14px weight 600 (`#1F4E79`), containing action toolbars, export icons, and record count badges.