# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope

This is Lab 2 (`Lab2-AndroidApp/flutter_androidApp`) of the PRM393 repo (nested git repo rooted at `PRM5M/`, branch `main`). Only work in this directory; `../../Lab1-DesktopApp` and `../../Lab3-XXX` are other labs. Run all Flutter commands from here.

Lab 2 is a copy of the Lab 1 Windows desktop app ("FAP Attendance", package `flutter_application_1`) that is being adapted to Android. Much of the code and docs still describe the desktop version, so check before assuming something is Android-ready.

## Commands

```powershell
flutter pub get
flutter analyze lib
flutter test                          # only test/widget_test.dart exists
flutter test test/widget_test.dart    # single file
flutter run -d <android-device-id>    # `flutter devices` to list; `-d windows` also still works
flutter build apk
```

## Local environment (this machine)

Flutter is at `C:\Users\LENOVO\flutter`; the Android SDK is at `D:\AndroidHolder\sdk` (`ANDROID_HOME`), and Gradle/AVD data live on D: (`GRADLE_USER_HOME`, `ANDROID_AVD_HOME`) because C: is nearly full. The emulator is `Medium_Phone_API_37.0`; start it detached (`cmd /c start "" emulator.exe -avd Medium_Phone_API_37.0`), since it dies when launched as a child of a tool shell. On the emulator, `cached_apps_freezer` is disabled so the OAuth callback survives while Chrome is in front.

## Configuration

A `.env` in this directory (git-ignored but declared as a Flutter asset in `pubspec.yaml`) needs `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_SPREADSHEET_ID`, and optionally `ATTENDANCE_NOTIFICATION_ENDPOINT` and `ATTENDANCE_TEACHER_EMAIL`. `main()` loads it via `flutter_dotenv` and only logs on failure.

The spreadsheet needs tabs named exactly `students`, `schedule`, `attendance`, with headers matching `_studentsHeaders` / `_scheduleHeaders` / `_attendanceHeaders` in `lib/services/google_sheet_service.dart`. Missing tabs or columns are reported as errors, not papered over. Seeding only appends `SAMPLE-` rows, and attendance submits must not duplicate a `session_id` + `student_id` pair. `test_samples/sample_students_SE1801.csv` is sample import data.

## Architecture

- **Google Sheets is the database.** `GoogleSheetService` owns Google OAuth (googleapis_auth, "Desktop app" client with a browser + local-port callback), sheet reads/writes, header validation and seeding. The refresh token is cached as `fap_attendance_oauth.json` in the app-support directory.
- **Android sign-in flow:** Android blocks network for backgrounded apps, so `clientViaUserConsent` (which exchanges the code while Chrome is in front) fails with "Failed host lookup oauth2.googleapis.com". `_requestMobileUserClient` therefore receives the code on a loopback server, waits for the app to resume (`AppLifecycleListener`), then exchanges it (PKCE). The user must switch back to the app after Chrome shows "Signed in". Desktop still uses `clientViaUserConsent`. `LoginPage` auto-signs in with the cached token; Logout navigates to `/login?logout=1`, which clears it.
- **Responsive layout:** pages switch layout at 700px (`MediaQuery.sizeOf(context).width < 700`): tables become card lists on phones (My Classes, Timetable, Export, Reports, attendance roster). Keep both layouts when editing.
- **Composition root is `lib/main.dart`:** it builds one `GoogleSheetService`, a `GoogleSheetsAttendanceRepository` and an `AttendanceStatsService`, and injects them via constructors into pages under a `go_router` `ShellRoute` (`AppShell`). Initial route `/login`; others: `/home`, `/my-classes`, `/timetable`, `/take-attendance`, `/attendance/:sessionId`, `/reports`, `/fap-sync` (ExportPage), `/ai-assistant`, `/settings`. No DI container or state-management package.
- **Two data paths:** attendance taking goes through the `AttendanceRepository` interface (`features/attendance/data/`, with a hard-coded `MockAttendanceRepository` beside the Sheets implementation); all other pages read aggregates from `AttendanceStatsService` (cached stats, `ok/warning/banned` risk, session status, warn/ban thresholds 15%/20% stored in `shared_preferences`). Saving attendance calls `stats.load(force: true)`.
- **Navigation:** `core/widgets/nav_bar.dart` defines `NavBar.items` once; the desktop `NavBar` and the `MobileNavBar` both read from it, so add routes there. `AppShell` switches between them for responsive layout.
- **Email risk alerts:** `AttendanceNotificationService` (called from the AI Assistant page) POSTs new `warning`/`banned` students and missing sessions to `ATTENDANCE_NOTIFICATION_ENDPOINT`, deduping with event keys in `shared_preferences`. The backend is a Firebase Cloud Function that is not in this repo; its contract is in `docs/firebase-email-notifications.md`. The docs say Firestore should replace the local dedupe store after migration.
- **Firebase is declared but unused:** `firebase_core`, `firebase_auth` and `cloud_firestore` are in `pubspec.yaml`, but nothing in `lib/` imports them, there is no `Firebase.initializeApp`, and there is no `android/app/google-services.json`. The Android `applicationId` is still `com.example.flutter_application_1`.
- **Legacy code:** `lib/screens/*` and `services/ai_report_service.dart` are not wired into `main.dart` or `features/`. Prefer `features/`.
- `windows/`, `ios/`, `macos/`, `linux/`, `web/` platform folders are checked in alongside `android/`. `design/` holds HTML/PNG UI mockups for visual reference only.
