# Current Screen Specification

**Target:** `Lab1-DesktopApp/flutter_desktopApp`  
**Source of truth for route reachability:** [lib/main.dart](../lib/main.dart)  
**Status vocabulary:** Code-confirmed means visible in current Flutter code; Runtime verification needed means it must be checked with a running app screenshot.

## Shared Screen Contract

All authenticated routes render inside [AppShell](../lib/core/widgets/app_shell.dart), except `/login`. The desktop shell contains `AppHeader`, `NavBar`, `BreadcrumbBar`, page content, and `AppFooter`. On widths below 700px, desktop NavBar/Footer are replaced by `MobileNavBar`.

## 1. Login

- **Route/file:** `/login` -> [login_page.dart](../lib/features/auth/login_page.dart)
- **Layout:** Centered, max-width 420px card on the surface background.
- **Components:** School icon, Academic Portal heading, sign-in explanation, Google sign-in button, inline error text, loading button state.
- **States:** Idle, Connecting, authentication error. Code-confirmed. Runtime screenshot needed for final spacing and OAuth browser behavior.
- **Interactions:** Sign-in calls `GoogleSheetService.signOut()`, then `init()`. Success navigates to `/take-attendance`; failure remains on login and displays `lastError`.
- **Navigation:** Entry route; success enters shell; no authenticated shell is shown on login.
- **Constraints:** No live Google account picker or error presentation can be confirmed from source alone.

## 2. Home / Lecturer Dashboard

- **Route/file:** `/home` -> [home_page.dart](../lib/features/home/home_page.dart)
- **Layout:** Scrollable list with title/date, refresh action, four statistic cards, today's sessions, and a quick guide/glossary.
- **Components:** Classes today, overall attendance, banned students, draft sessions; session ListTiles with status; guide card.
- **States:** Loading, data error, empty today's sessions, loaded data, refresh. Code-confirmed.
- **Interactions:** Refreshes `AttendanceStatsService`; tapping a session opens `/attendance/:sessionId`.
- **Navigation:** NavBar Home; session row -> Attendance Detail.
- **Constraints:** Data depends on current Google Sheets contents and the current date; screenshots must use a known dataset.

## 3. My Classes

- **Route/file:** `/my-classes` -> [my_classes_page.dart](../lib/features/classes/my_classes_page.dart)
- **Layout:** Scrollable class summary DataTable; selecting a class changes to an in-page session list.
- **Components:** Class, subject, student count, progress, warning, banned columns; class detail header and session cards.
- **States:** Loading, load error, class table, selected class session view. Code-confirmed.
- **Interactions:** Select a table row; back button returns to class table; session card opens Attendance Detail.
- **Navigation:** NavBar My Classes; class/session selection -> `/attendance/:sessionId`.
- **Constraints:** Selected-class view is state inside one route, not a separate route.

## 4. Weekly Timetable

- **Route/file:** `/timetable` -> [timetable_page.dart](../lib/features/timetable/timetable_page.dart)
- **Layout:** Week header with previous/Today/next controls and a horizontally scrollable 7-day x 8-slot grid.
- **Components:** Day/date header, slot labels, session cells, session status colors.
- **States:** Loading, load error, current week, moved week, empty cells. Code-confirmed.
- **Interactions:** Move week, return to current week, tap session cell to open Attendance Detail.
- **Navigation:** NavBar Timetable; session cell -> `/attendance/:sessionId`.
- **Constraints:** Grid has a code-defined width of 1280px and horizontal scrolling; actual desktop/mobile fit needs screenshot verification.

## 5. Take Attendance Browse

- **Route/file:** `/take-attendance` -> [attendance_browse_page.dart](../lib/features/attendance/attendance_browse_page.dart)
- **Layout:** Page title and seed action, then Today’s sessions and Upcoming classes horizontal card rows inside a max-width 1400px content area.
- **Components:** Session count chips, left/right arrow controls, session cards with subject, class, room, date, slot, session progress.
- **States:** Loading, load error, no sessions, populated sessions, seed confirmation, seed success/error snackbar. Code-confirmed.
- **Interactions:** Mouse/touch horizontal drag, arrow scrolling, card tap, seed sample data after confirmation.
- **Navigation:** NavBar Take Attendance; card -> `/attendance/:sessionId`.
- **Constraints:** Two rows use separate scroll controllers. Actual card density and drag behavior need runtime verification.

## 6. Attendance Detail

- **Route/file:** `/attendance/:sessionId` -> [attendance_detail_page.dart](../lib/features/attendance/attendance_detail_page.dart)
- **Layout:** Scrollable max-width 1400px content with session identification card, control bar, roster table, and save/autosave area. Table supports vertical and horizontal scrolling.
- **Components:** Session metadata, Enrolled/Present/Absent/Rate counters, Mark All Present, Mark All Absent, Reset, Save Draft, Submit, search field, status filter, student photo/initial, roll number, full name/major, gender, toggle, cumulative absence chip, note field.
- **States:** Loading, session-not-found, load error, loaded, filtered roster, saving, submitted, save error. Code-confirmed.
- **Interactions:** Present/Absent toggle, mark all, reset to initial statuses, search, status filter, draft save, submit confirmation, cumulative absence recalculation.
- **Navigation:** Entered from Home, My Classes, Timetable, or Browse. Take Attendance remains the active desktop nav item for `/attendance/*`.
- **Constraints:** Current repository data is authoritative. `AttendanceDetailPage` calls `getSessions`, `studentsForSession`, `isSessionSubmitted`, `saveAttendance`; final remote behavior requires a connected Sheets run.

## 7. FAP Sync / Export

- **Route/file:** `/fap-sync` -> [export_page.dart](../lib/features/export/export_page.dart)
- **Layout:** Scrollable page with title/refresh/export actions, class/date filter panel, student import panel, and sync-status table.
- **Components:** Target Class selector, from/to date pickers, reset filters, CSV export, fallback class code, CSV import, Excel import, session table, Submitted/Draft/Not Taken chips.
- **States:** Loading, load error, filtered table, exporting, importing, empty/no-record export, success/error snackbars. Code-confirmed.
- **Interactions:** Refresh Sheets data, filter class/dates, export CSV through file picker or application documents fallback, open export folder, import students, refresh stats.
- **Navigation:** NavBar item is labelled `Export` in `NavBar`, route is `/fap-sync`, page title is `Export & FAP Sync`.
- **Constraints:** This is not the same as a purely visual Stitch “FAP Sync Center”; file-system and Google Sheets behavior must be verified on the demo Windows machine.

## 8. AI Assistant

- **Route/file:** `/ai-assistant` -> [ai_assistant_page.dart](../lib/features/ai_assistant/ai_assistant_page.dart)
- **Layout:** Scrollable assistant workspace with automatic scan messages and action controls.
- **Components:** At-risk students action, highest absence subject action, student history selector/action, message list, notification status.
- **States:** Loading, load/notification error messages, no-risk result, risk result, pending notification dispatch, selected student history. Code-confirmed.
- **Interactions:** Runs rule-based risk analysis, finds highest-absence subject, appends student history, automatically attempts notification dispatch during load.
- **Navigation:** NavBar AI Assistant; no route-specific child navigation found.
- **Constraints:** Despite the design name “AI Assistant”, the code explicitly describes rule-based analysis and may use notification configuration; no claim of a general chat model should be made without runtime/config evidence.

## 9. Reports

- **Route/file:** `/reports` -> [reports_page.dart](../lib/features/reports/reports_page.dart)
- **Layout:** Title/export action, semester/subject/class filters, horizontally scrollable risk table.
- **Components:** Filters, Export CSV, student, class, sessions held, absent, absence %, status columns.
- **States:** Loading, load error, filtered rows, empty result, export success/error. Code-confirmed.
- **Interactions:** Change filters and export report CSV to the application documents directory.
- **Navigation:** NavBar Reports; no route-specific child navigation found.
- **Constraints:** Current report thresholds come from `AttendanceStatsService`; confirm whether this corresponds to the original Stitch report semantics.

## 10. Settings

- **Route/file:** `/settings` -> [settings_page.dart](../lib/features/settings/settings_page.dart)
- **Layout:** Centered max-width 900px scrollable settings content with thresholds, demo data, and account cards.
- **Components:** Warning threshold input, banned threshold input, Save, Regenerate sample data, Google account status.
- **States:** Loading, load error, saving, invalid input, threshold validation error, seed confirmation, seed success/error. Code-confirmed.
- **Interactions:** Persist warning/ban thresholds through `AttendanceStatsService`; regenerate sample data after destructive confirmation.
- **Navigation:** NavBar Settings; no child route.
- **Constraints:** Regenerate explicitly deletes/replaces test spreadsheet data according to the dialog text. This must be demonstrated only with safe test data.

## Legacy / Orphaned Files

These files exist under `lib/screens/` but are not referenced by the current `GoRouter` in [main.dart](../lib/main.dart):

- [main_screen.dart](../lib/screens/main_screen.dart)
- [class_selection_screen.dart](../lib/screens/class_selection_screen.dart)
- [attendance_screen.dart](../lib/screens/attendance_screen.dart)
- [report_screen.dart](../lib/screens/report_screen.dart)
- [settings_screen.dart](../lib/screens/settings_screen.dart)

They are **not current reachable screens**. Their presence does not prove that their flows remain part of the demo. The reason they were retained or abandoned is not confirmed by the supplied context.

## Required Runtime Evidence

Capture screenshots for `/login`, `/home`, `/my-classes`, `/timetable`, `/take-attendance`, `/attendance/:sessionId`, `/fap-sync`, `/ai-assistant`, `/reports`, and `/settings`, plus at least one loading/error/empty or recovery state. The source proves route/widget existence, but not final visual parity, data content, OAuth behavior, or responsive layout.
