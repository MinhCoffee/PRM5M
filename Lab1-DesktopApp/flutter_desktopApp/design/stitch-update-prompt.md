# Stitch Update Prompt

Update the existing Stitch project so its design documents and screen prototypes match the current Flutter implementation in `Lab1-DesktopApp/flutter_desktopApp`.

## Source of Truth

Use the current Flutter route graph in `lib/main.dart`, the current theme in `lib/core/theme/app_theme.dart`, the shared shell in `lib/core/widgets/`, and the current screen specifications in `design/screen-spec-current.md`.

Use the supplied runtime screenshots as the visual authority when they are available. Do not invent colors, dimensions, states, data, routes, or features that are not present in Flutter or in an explicitly supplied screenshot.

Keep the existing institutional utility style from `design/DESIGN.md`: Inter typography, restrained 6px operational corners, FPT orange/blue/green accent strip, blue/navy data surfaces, compact tables, high-density academic workflows, and clear attendance status semantics.

## Screens to Keep and Update

Keep and update these current reachable screens:

1. `/login` - Google authentication screen with idle, connecting, and authentication-error states.
2. `/home` - live attendance dashboard with refresh, summary cards, today sessions, and session links.
3. `/my-classes` - class summary table and selected-class session view.
4. `/timetable` - weekly 7-day / 8-slot timetable with previous week, Today, next week, and session links.
5. `/take-attendance` - horizontal Today and Upcoming session-card rows with arrow controls and mouse/touch drag scrolling.
6. `/attendance/:sessionId` - session metadata, live counters, search/filter, roster table, Present/Absent controls, cumulative absence warning, Reset, Save Draft, and Submit confirmation.
7. `/fap-sync` - current page title `Export & FAP Sync`, with class/date filters, CSV export, CSV/Excel student import, refresh, and Submitted/Draft/Not Taken statuses.
8. `/ai-assistant` - rule-based attendance risk analysis, highest-absence subject, student history, and notification status. Do not represent this as unrestricted conversational AI.
9. `/reports` - semester/subject/class filters, attendance-risk table, and CSV export.
10. `/settings` - warning and ban threshold controls, save feedback, destructive sample-data regeneration confirmation, and Google account status.

## Shell Requirements

For authenticated screens, preserve this structure:

`AppHeader -> NavBar -> BreadcrumbBar -> page content -> AppFooter`

- Header: 4px orange/blue/green strip, desktop user/session context, working Logout action.
- NavBar: route-aware active state. Keep current labels and routes from Flutter. Note that the visible label is `Export` while the route is `/fap-sync`.
- Breadcrumb: `FU - HCM > Academic Attendance Workbench`.
- Content: respect the current max-width and page-specific scrolling behavior.
- Footer: desktop shell only.
- At widths below 700px, represent the current mobile behavior: hide desktop NavBar/Footer and show the four-primary-destination bottom navigation plus More menu.

## Navigation Rules

- Initial navigation is `/login`.
- Successful Google authentication navigates to `/take-attendance`.
- Logout navigates back to `/login`.
- Home, My Classes, Timetable, and Take Attendance session cards/cells navigate to `/attendance/:sessionId`.
- Attendance Detail remains selected under Take Attendance in the active navigation state.
- Do not add extra routes for in-page selected class view, filters, dialogs, loading states, or mobile variants.
- Do not restore the old `lib/screens/` class-selection/report/attendance flow as new Stitch screens. Those files are not reachable from the current GoRouter.
- Do not delete or claim to remove any page unless the project owner explicitly confirms the removal.

## Interaction and State Fidelity

Represent the states evidenced by Flutter:

- Loading and data-load error states for Sheets-backed pages.
- Empty session state with `Create sample data` recovery on Take Attendance.
- Login connecting/error state.
- Attendance Detail search, status filter, initial-status Reset, draft save, submit confirmation, submitted state, and save error.
- FAP Sync exporting/importing, empty export warning, file export success/error, and import success/error.
- Reports filtered/empty/export feedback.
- Settings invalid threshold, validation error, save feedback, and destructive seed confirmation.

Keep current Google Sheets and repository behavior visible as operational states, but do not expose credentials or generate fake OAuth claims.

## Design/Flutter Synchronization Rules

- Keep current Flutter labels and route names unless a supplied runtime screenshot proves they differ.
- Update the Stitch prototype using the attached/current Flutter screenshots after they are provided.
- Produce a before/after comparison for each of the ten reachable screens.
- Mark any mismatch that cannot be resolved from source or screenshots as `NEEDS OWNER CONFIRMATION`.
- Do not add a new page to reach an arbitrary screen count.
- Do not restore a removed page, reintroduce an old navigation branch, or invent a reason for a page removal.
- Do not claim that the design is approved or pixel-matched until runtime screenshots have been reviewed.
