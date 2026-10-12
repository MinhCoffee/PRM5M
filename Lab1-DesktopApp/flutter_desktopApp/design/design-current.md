# AttendEase / FAP Attendance - Current Design

**Document status:** Current implementation evidence for demo preparation  
**Target project:** `Lab1-DesktopApp/flutter_desktopApp`  
**Reference design:** [DESIGN.md](DESIGN.md)  
**Last reviewed:** 2026-10-12

## Scope and Evidence Rules

This document describes the Flutter application currently wired from `lib/main.dart`. It does not describe the parallel `Lab2-AndroidApp/flutter_androidApp` project. The original design document and Stitch exports remain unchanged.

Evidence priority:

1. Current Flutter route and widget code.
2. Current Flutter theme and shared widgets.
3. Existing Stitch `screen.png` and `code.html` files.
4. Runtime screenshots supplied later by the project owner.

A statement marked **Code-confirmed** is visible in the current source. A statement marked **Runtime verification needed** requires a screenshot or a manual run on the target demo environment.

## Application Map

The current router in [lib/main.dart](../lib/main.dart) starts at `/login` and defines a `ShellRoute` for the application workspace.

| Route | Current screen | Code-confirmed status |
|---|---|---|
| `/login` | Google login | Reachable initial route |
| `/home` | Lecturer dashboard | Reachable |
| `/my-classes` | Class overview and class sessions | Reachable |
| `/timetable` | Weekly timetable | Reachable |
| `/take-attendance` | Attendance session browser | Reachable |
| `/attendance/:sessionId` | Attendance detail | Reachable from session selection |
| `/fap-sync` | Export and FAP sync workspace | Reachable; route name is FAP Sync while class is `ExportPage` |
| `/ai-assistant` | AI assistant | Reachable |
| `/reports` | Attendance reports | Reachable |
| `/settings` | Shared thresholds and demo data settings | Reachable |

The desktop shell is implemented by [app_shell.dart](../lib/core/widgets/app_shell.dart). At widths below 700px it hides the desktop navigation/footer and uses `MobileNavBar` instead. **Runtime verification needed:** exact responsive appearance at the demo window size.

## Design Tokens Used by Flutter

The current implementation is driven by [app_theme.dart](../lib/core/theme/app_theme.dart) in code.

### Colors

| Token | Current code value | Use |
|---|---|---|
| `surface` | `#F8F9FF` | Scaffold background |
| `surfaceLow` | `#EFF4FF` | Breadcrumb/footer surfaces |
| `surfaceContainer` | `#E5EEFF` | Secondary controls and cards |
| `surfaceHigh` | `#DCE9FF` | Panel header surfaces |
| `onSurface` | `#0B1C30` | Primary text |
| `onSurfaceVariant` | `#404751` | Secondary text |
| `primary` | `#0072BC` | Main actions and active states |
| `primaryDark` | `#005994` | Table headers and active navigation |
| `secondary` | `#35618D` | Secondary actions |
| `tertiary` | `#BA4C00` | Submit/warning accent |
| `orange` | `#F36F21` | Tricolor strip |
| `green` | `#6CB33F` | Tricolor strip and positive status |
| `error` | `#D93025` | Error/absence status |

The original `DESIGN.md` also defines a broader palette. Where the original palette and code differ, this current document follows code and records the difference in [design-changes.md](design-changes.md).

### Typography

`ThemeData.fontFamily` is `Inter`. The current theme defines Material text styles at 20, 16, 14, 15, 13, 12, and 11 pixels with the weights shown in [app_theme.dart](../lib/core/theme/app_theme.dart). **Runtime verification needed:** the Inter font is named in the theme, but the repository does not include a local Inter font asset in `pubspec.yaml`.

### Shape and Controls

- Cards and inputs use a 6px radius in code.
- Input fields are dense, filled, and use an 8px horizontal / vertical content padding configuration.
- Cards use white fill, zero elevation, and a `#D1D5DB` border.
- Status chips are implemented by [status_chip.dart](../lib/core/widgets/status_chip.dart) with Present, Absent, Warning, and Neutral variants.
- Table headers use `AppColors.primaryDark`; table rows use alternating white and `#F8FAFC` backgrounds in the current feature pages.

Exact visual hover/focus behavior and final pixel dimensions require runtime screenshots.

## Global Shell

- **Top accent:** 4px orange/blue/green strip in [app_header.dart](../lib/core/widgets/app_header.dart).
- **Header:** 60px desktop / 56px mobile, with logo icon, portal title, semester and campus tags on desktop, user identity, and logout.
- **Desktop navigation:** 48px `NavBar`; current route is read from `GoRouterState` and active navigation uses `primaryDark`.
- **Breadcrumb:** 32px `BreadcrumbBar` with `FU - HCM > Academic Attendance Workbench`.
- **Content:** `AppShell` gives the child the remaining height; individual pages provide their own lists/scroll views. Many pages constrain their content with a 1400px maximum or use full-width list/table surfaces.
- **Footer:** desktop only, through `AppFooter`.
- **Mobile:** `MobileNavBar` exposes four primary destinations and a More bottom sheet for remaining destinations.

## Current Data Boundary

The live desktop app creates:

- `GoogleSheetService` for authentication and Sheets operations.
- `GoogleSheetsAttendanceRepository` for session/student/attendance access.
- `AttendanceStatsService` for aggregate statistics and shared warning/ban thresholds.

The initial design shows mostly static Stitch content. The current UI therefore includes loading, error, empty, refresh, seed, save, and export states that were not represented in the original static screens.

## Requirement Coverage for the Course Demo

### Screen count

The current GoRouter exposes 10 different reachable screens/routes: Login, Home, My Classes, Timetable, Take Attendance Browse, Attendance Detail, FAP Sync/Export, AI Assistant, Reports, and Settings. This satisfies an eight-screen count based on Flutter route reachability. It does **not** prove that the Stitch/Figma prototype contains the same number of distinct screens; that requires reviewing the updated Stitch project or its exported screen inventory.

### Flow 1 - Authenticate and open an attendance session

`/login` -> Google connection -> `/take-attendance` -> select a session card -> `/attendance/:sessionId`.

Alternative branch: if Google initialization fails, the login page remains visible with an error. If the schedule is empty, Take Attendance shows an empty state with `Create sample data` recovery.

### Flow 2 - Find a session through planning views

`/home` or `/my-classes` or `/timetable` -> select today/class/week session -> `/attendance/:sessionId`.

Alternative branch: My Classes can remain in its class-summary view or enter an in-page selected-class session view; Timetable can move to previous/next week or return to Today.

### Flow 3 - Record, submit, and review attendance

Attendance Detail -> search/filter roster -> toggle Present/Absent -> Save Draft or Submit confirmation -> FAP Sync/Reports/AI Assistant review.

Alternative/error branches: Reset returns to the loaded initial statuses; Save/Submit can show an error snackbar; FAP Sync can export filtered data, report no records, or import CSV/Excel students; Reports can return an empty filtered result; AI Assistant can report no risk or pending/failed notification dispatch.

These flows and branches are code-confirmed as route/widget behavior. Their visual completion and usability still require runtime screenshots. No claim is made that the Stitch/Figma prototype meets the course screen-count requirement until the updated prototype itself is counted.

## Known Current Deviations

- The app is Google Sheets-backed at runtime instead of being a static mock-only prototype.
- The original Stitch screen names use “AttendEase”; the current visible Flutter title is “Academic Portal - Attendance”.
- FAP Sync is implemented by `ExportPage` and includes CSV export plus CSV/Excel student import.
- Attendance Detail has search, status filtering, mark-all actions, reset, draft save, submit confirmation, and cumulative absence state.
- Settings edits warning/ban thresholds and can regenerate demo data.
- The desktop shell has a mobile breakpoint and mobile navigation not shown in the desktop Stitch shell.
- Some older files remain under `lib/screens/` but are not reachable from the current `GoRouter`; see [screen-spec-current.md](screen-spec-current.md) and [design-changes.md](design-changes.md).

## Verification Needed Before Demo

- Capture one runtime screenshot per reachable route at the actual demo window size.
- Confirm that Google OAuth can complete with the configured desktop credentials.
- Confirm loaded Google Sheets data, empty-sheet behavior, and error recovery.
- Confirm whether the final public product name should remain “Academic Portal - Attendance” or return to “AttendEase”.
- Confirm whether the Stitch project should include desktop-only shell details or the mobile breakpoint too.
