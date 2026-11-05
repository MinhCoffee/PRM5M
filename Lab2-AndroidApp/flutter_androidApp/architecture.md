# Architecture — FAP Attendance (PRM393 Lab 3)

The app follows **MVVM**: Views never touch the Firebase SDK. Every Firebase
capability sits behind a service interface, so view models can be unit-tested
with fakes (see `test/`).

```
View (pages/widgets)  ->  ViewModel (ChangeNotifier)  ->  Service interface  ->  Firebase SDK
lib/features/*/*_page.dart  viewmodel/*_viewmodel.dart    core/services/firebase/   firebase_* packages
```

## Layers and rules

| Layer | Location | May depend on | Must NOT depend on |
|---|---|---|---|
| View | `lib/features/<feature>/*_page.dart`, `lib/core/widgets` | its ViewModel, theme | any `package:firebase_*`, `google_sign_in` |
| ViewModel | `lib/features/<feature>/viewmodel/` | service **interfaces** (`I...Service`), `AttendanceStatsService`, repositories | Flutter widgets, Firebase SDK |
| Service | `lib/core/services/firebase/` | Firebase SDK, `shared_preferences` | views, view models |
| Composition | `lib/core/di/service_locator.dart`, `lib/main.dart` | everything | — |

Only `lib/main.dart` imports `firebase_core` / `firebase_crashlytics` (to
initialise Firebase and install the global error hooks); everything else goes
through the service layer. A grep for `package:firebase_` outside
`core/services/firebase` returns `main.dart` only. (`google_sheet_service.dart`
also imports `google_sign_in`, but only to obtain the Google Sheets OAuth scope —
it is the attendance data backend, not a Firebase service.)

## State management: Provider

`main.dart` creates each screen's ViewModel with `ChangeNotifierProvider`
(`_screen<T>()`), so a ViewModel is created **once per route entry** and disposed
when the route is left. The page receives it as a constructor argument and
rebuilds with `ListenableBuilder`. `ServiceLocator` is exposed via
`Provider<ServiceLocator>` and builds view models (`createXxxViewModel`), which
keeps wiring in one place and lets tests inject fakes
(`ServiceLocator.setMockInstance`).

Every ViewModel exposes a `ViewState<T>` (`initial / loading / data / empty / error`)
rendered by `core/widgets/state_view.dart`, so loading, empty and error states look the same on every screen.

## The six Firebase services

| # | Service | Interface | Implementation | Used by |
|---|---|---|---|---|
| 1 | Authentication | `IAuthService` | `FirebaseAuthService` (Google Sign-In -> `signInWithCredential`) | `AuthViewModel`, `ProfileViewModel`, router guard |
| 2 | Cloud Storage | `IStorageService` | `CloudinaryStorageService` -> unsigned upload to `reports/{uid}/{ts}_{file}` (Cloudinary free plan) | `ReportsViewModel`, `ExportViewModel` (via `CloudBackupMixin`) |
| 3 | Cloud Messaging | `IMessagingService` | `FirebaseMessagingService` | `NotificationsViewModel`, header badge, router |
| 4 | Analytics | `IAnalyticsService` | `FirebaseAnalyticsService` | all ViewModels |
| 5 | Crashlytics | `ICrashlyticsService` | `FirebaseCrashlyticsService` + global hooks in `main.dart` | all ViewModels, Settings test buttons |
| 6 | Remote Config | `IRemoteConfigService` | `FirebaseRemoteConfigService` | `HomeViewModel`, `SettingsViewModel`, `AiAssistantViewModel` |

Firestore is **not** used.

### Design rules that keep the evidence honest

* **No fake success.** If Firebase is not initialised or a call fails, the
  service throws a typed failure (`AuthException`, `StorageFailure`) or returns
  `null` (FCM token) — it never invents a user, a download URL or a token.
* **Failures are explained to the user** (cancelled sign-in, offline, permission
  denied) and offer a retry; a *cancelled* sign-in is not recorded as a crash.
* **No PII in analytics/logs**: only the Firebase `uid`; no emails, names or
  student ids in event parameters or the evidence log.

## Navigation and protection

`go_router` with a `redirect` guard: every route except `/login` requires a real
Firebase session (`authService.currentUser`). `refreshListenable` re-runs the
guard when the auth stream changes, so signing out immediately returns to
`/login`. A deep link or tapped notification received while signed out is
remembered (`_pendingRoute`) and opened right after login.

Routes: `/login`, `/home`, `/take-attendance`, `/attendance/:sessionId`,
`/my-classes`, `/timetable`, `/reports`, `/fap-sync`, `/ai-assistant`,
`/notifications`, `/profile`, `/settings`.

## Data flow per service

* **Auth**: `LoginPage` -> `AuthViewModel.signInWithGoogle()` ->
  `GoogleSignInBootstrap` (single `GoogleSignIn.initialize()`) -> Firebase
  credential -> `currentUser` -> Sheets connection -> `/home`.
* **Storage**: Export/Reports -> CSV saved locally -> `CloudBackupMixin.backupToCloud()`
  -> multipart POST to Cloudinary (unsigned preset) -> real `secure_url`; failures
  surface in `CloudBackupBanner` with *Retry*. History is stored locally per user.
  (Firebase Storage needs Blaze; `FirebaseStorageService` is kept but unused.)
* **FCM**: `FirebaseMessagingService.initialize()` requests the Android 13+
  permission, then handles three states — foreground (`onMessage`), background
  tap (`onMessageOpenedApp`), terminated tap (`getInitialMessage`) — stores
  history in `shared_preferences`, and `routeForNotification()` maps the payload
  (`data.route` / `data.type`) to a screen. A top-level
  `firebaseMessagingBackgroundHandler` persists messages received in the background.
* **Analytics**: see `docs/analytics-plan.md` (7 required events + extras).
* **Crashlytics**: `FlutterError.onError` and `PlatformDispatcher.onError` in
  `main.dart`; handled errors via `recordError`; user id + custom keys; a
  confirmed test crash in Settings.
* **Remote Config**: defaults in `FirebaseRemoteConfigService.defaults`;
  `show_banner` toggles the Home banner and `max_items` caps today's session list.
  Debug builds fetch each time; release builds cache for 5 minutes.

## Testing

`test/viewmodel_test.dart` (auth flows with fakes), `test/firebase_services_test.dart`
(cloud backup success/failure/retry, FCM history + routing, Remote Config
defaults/overrides), `test/widget_test.dart` (login screen, route guard).
End-to-end device tests are planned in `docs/artemis-test-plan.md`.

## Dependencies (`pubspec.yaml`)

`firebase_core`, `firebase_auth`, `firebase_storage`, `firebase_messaging`,
`firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`,
`google_sign_in`, `provider`, `go_router`, `shared_preferences`, plus the
Google Sheets stack that stores attendance data.
