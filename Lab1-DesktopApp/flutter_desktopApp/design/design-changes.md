# Design Changes: Stitch to Current Flutter

**Target project:** `Lab1-DesktopApp/flutter_desktopApp`  
**Original design:** [DESIGN.md](DESIGN.md) plus the Stitch exports under this directory  
**Current route evidence:** [lib/main.dart](../lib/main.dart)  
**Review date:** 2026-10-12

## Comparison Table

| Original Stitch screen/function | Current Flutter screen/file | Status | Concrete difference and evidence |
|---|---|---|---|
| Academic Utility Portal / global design system | [app_theme.dart](../lib/core/theme/app_theme.dart), [app_shell.dart](../lib/core/widgets/app_shell.dart), shared widgets | Adjusted | The current app uses the original palette as a base but code defines its own `AppColors`, Material 3 theme, 6px cards, 4px strip, desktop/mobile shell, and route-aware navigation. |
| Lecturer Dashboard | `/home`, [home_page.dart](../lib/features/home/home_page.dart) | Adjusted | Current screen loads live Sheets-derived stats, refreshes, shows classes today, overall attendance, banned students, drafts, sessions, and a quick guide. The original Stitch dashboard is static design content. |
| My Classes | `/my-classes`, [my_classes_page.dart](../lib/features/classes/my_classes_page.dart) | Current implementation; design mapping not found | The current route exists and supports class summary -> selected class sessions -> Attendance Detail. No matching `attendease_my_classes` design folder was found in the Lab1 design directory. |
| Weekly Timetable | `/timetable`, [timetable_page.dart](../lib/features/timetable/timetable_page.dart) | Adjusted | Current implementation is a 7-day x 8-slot grid with week navigation and session click-through. The design folder is `attendease_weekly_timetable`. Code uses a 1280px grid width and horizontal scrolling. |
| Take Attendance Browse | `/take-attendance`, [attendance_browse_page.dart](../lib/features/attendance/attendance_browse_page.dart) | Adjusted | Stitch presents subject/card rows. Flutter keeps that composition but adds live repository loading, Today/Upcoming grouping, seed sample data, loading/error/empty states, arrows, and drag scrolling. |
| Attendance Detail Marking | `/attendance/:sessionId`, [attendance_detail_page.dart](../lib/features/attendance/attendance_detail_page.dart) | Adjusted | Flutter keeps the roster/session composition and adds async repository loading, search, status filter, Mark All Present/Absent, Reset to initial values, Save Draft, Submit confirmation/persistence, error state, and `AttendanceStatsService` refresh. |
| Attendance Report | `/reports`, [reports_page.dart](../lib/features/reports/reports_page.dart) | Adjusted | Flutter provides semester/subject/class filters, risk rows, and CSV export. It is backed by `AttendanceStatsService`, unlike the static Stitch report. |
| FAP Sync Center | `/fap-sync`, [export_page.dart](../lib/features/export/export_page.dart) | Adjusted / renamed in navigation | `NavBar` labels the route `Export`; route remains `/fap-sync`; page title is `Export & FAP Sync`. Flutter includes CSV export, CSV/Excel student import, class/date filters, refresh, and sync-status chips. |
| AI Assistant | `/ai-assistant`, [ai_assistant_page.dart](../lib/features/ai_assistant/ai_assistant_page.dart) | Adjusted | Flutter implements rule-based risk analysis, highest-absence subject, student history, and notification dispatch. The word “AI” in the design must not be interpreted as proof of a general chat model. |
| Login | `/login`, [login_page.dart](../lib/features/auth/login_page.dart) | Adjusted | Flutter connects through `GoogleSheetService`, shows loading/error states, signs out cached OAuth credentials before connecting, then routes to `/take-attendance`. Stitch shows a static institutional Google Workspace login composition. |
| Settings | `/settings`, [settings_page.dart](../lib/features/settings/settings_page.dart) | Adjusted | Flutter exposes warning/ban thresholds, persistent settings, destructive sample-data regeneration, and Google account status. |
| AttendEase logo/brand asset | [app_header.dart](../lib/core/widgets/app_header.dart), [login_page.dart](../lib/features/auth/login_page.dart) | Adjusted / asset usage not equivalent | Current code uses a school icon and text rather than the external image/logo visible in Stitch HTML. The intended final brand is not confirmed. |
| Legacy class-selection / old attendance flow | `lib/screens/*.dart` | Orphaned / not reachable | `main.dart` routes through `lib/features/*`; legacy `main_screen.dart`, `class_selection_screen.dart`, `attendance_screen.dart`, `report_screen.dart`, and `settings_screen.dart` remain on disk but are not connected to current GoRouter. No deletion reason was supplied. |

## Changes with Confirmed Reasons

No page-removal or page-merging reason has been confirmed by the project owner in the available context. The current documents therefore do not claim that a page was removed because it was redundant, replaced, or out of scope. The only code-confirmed fact is reachability: a route is current when it is declared in `main.dart` and can be reached through the current router; a legacy file is orphaned when it is not referenced by that route graph.

The following implementation changes are code-confirmed, but their product/design rationale still needs owner confirmation:

- Google Sheets is now an active data boundary instead of only Stitch mock content.
- FAP Sync is implemented as an export/import workspace.
- Settings owns shared risk thresholds and sample-data regeneration.
- Login performs Google authentication and can fail before entering the shell.
- The app supports a mobile shell below 700px.
- Attendance Detail supports more operations than the original static marking view.

## Required Before/After Images

### Existing “before” images

The following Stitch images exist and should be used as the original reference set:

- `design/attendease_login/screen.png`
- `design/attendease_lecturer_dashboard/screen.png`
- `design/attendease_take_attendance_browse/screen.png`
- `design/attendease_attendance_detail_marking/screen.png`
- `design/attendease_weekly_timetable/screen.png`
- `design/attendease_attendance_report/screen.png`
- `design/attendease_fap_sync_center/screen.png`
- `design/attendease_ai_assistant/screen.png`
- `design/attendease_settings/screen.png`
- `design/attendease_logo/screen.png`

### Missing “after” images

Runtime screenshots are not present in the reviewed source. Capture the same reachable Flutter screens at the actual demo window size and label them with route and state:

- `after-login.png`
- `after-home-loaded.png`
- `after-my-classes-selected.png`
- `after-timetable-week.png`
- `after-take-attendance.png`
- `after-attendance-detail-loaded.png`
- `after-attendance-detail-error-or-empty.png`
- `after-fap-sync-filtered.png`
- `after-ai-assistant-loaded.png`
- `after-reports-filtered.png`
- `after-settings.png`

Do not claim pixel parity until these images have been compared against the Stitch references.

## Open Change Questions

1. Which exact 1-2 pages did you remove from the original plan, and was each removal intentional or temporary?
2. Should the legacy `lib/screens/` flow be considered abandoned and excluded from the demo, or should it be deleted later?
3. Should the current product name be `AttendEase`, `FAP Attendance`, or `Academic Portal - Attendance`?
4. Is the mobile breakpoint part of the demo requirement, or should the Stitch update remain desktop-only?
5. Which Google Sheets/OAuth behavior should be represented in Stitch: successful connection only, or error/loading states too?
