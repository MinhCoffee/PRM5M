# Firebase evidence checklist (what to capture, per service)

Tick each box only after you have **really** done it on a device and saved the
screenshot in `docs/evidence/` (create the folder). Name files
`<service>-<n>-<what>.png`. Do not edit screenshots. Never fabricate results.

Test device/emulator: ______________________  Android version: ______  Date: ________

## 1. Authentication
- [ ] Login screen before sign-in
- [ ] Google account picker -> signed in -> Home (after)
- [ ] Console -> Authentication -> Users shows the test user
- [ ] **Cancel** the Google picker -> readable message, no crash
- [ ] **Airplane mode** during sign-in -> "Mất kết nối mạng" message, *Retry* works
- [ ] Sign out -> back on login; pressing back / opening a protected route does not show the app
- [ ] Notes: `uid` shown in Profile matches Console

## 2. Cloud Storage
- [ ] Reports -> Export CSV -> progress bar visible in banner
- [ ] Final download URL shown (copy button)
- [ ] Console -> Storage -> `reports/<uid>/<file>.csv` exists
- [ ] `firebase/storage.rules` deployed; screenshot of Rules tab (no `if true`)
- [ ] **Error case A**: airplane mode while uploading -> failure message + *Thử lại tải lên*
- [ ] **Error case B**: Rules Playground (or a second account) cannot read `reports/<other-uid>/...`

## 3. Cloud Messaging
- [ ] Profile shows the real FCM token
- [ ] Permission dialog on Android 13+ (accept)
- [ ] Console test message received while **foreground** (appears in Notification centre)
- [ ] ... while **background** (system tray) -> tap -> opens the mapped screen
- [ ] ... while **terminated** -> tap -> app launches into the mapped screen
- [ ] Notification centre lists history (survives app restart)
- [ ] **Error case**: deny permission -> banner "đã từ chối quyền" in Notification centre
- [ ] Custom data used for routing: `route=/reports` or `type=risk_alert`

## 4. Analytics (DebugView)
Run `adb shell setprop debug.firebase.analytics.app com.example.flutter_application_1`.

| Event | Trigger | DebugView screenshot |
|---|---|---|
| `login` | Sign in | [ ] |
| `screen_view` | open any screen | [ ] |
| `attendance_marked` | save attendance | [ ] |
| `attendance_submitted` | submit attendance | [ ] |
| `export_report` | export CSV | [ ] |
| `filter_changed` | change a Reports filter | [ ] |
| `save_thresholds` | Settings -> save thresholds | [ ] |
- [ ] User ID set (uid) and no email/name in any parameter
- [ ] **Error case**: offline -> app still works; events flush when back online

## 5. Crashlytics
- [ ] Non-fatal: Settings -> "Gửi Non-fatal" -> appears in Console (Non-fatals tab)
- [ ] Fatal test crash: Settings -> confirm dialog -> app closes -> reopen -> report in Console
- [ ] Crash detail shows **user id** and custom keys (`test_origin`, `intentional_test_crash`, `auth_provider`)
- [ ] A real handled error shows a message to the user (e.g. attendance save offline)
- [ ] Confirm the crash button is **not** reachable in normal flows (only Settings, behind a dialog)

## 6. Remote Config
- [ ] Before: Home shows banner and all of today's sessions; Console parameter values
- [ ] Change `show_banner=false` -> Publish -> tap Home refresh -> banner hidden
- [ ] Change `max_items=1` -> Publish -> refresh -> list capped, note "1/N ca (max_items)"
- [ ] After: Console screenshot with new values
- [ ] **Error case**: airplane mode -> app shows last/default values, no crash
- [ ] Explain in the report: debug fetch interval = 0; release = 5 min; values cached by the SDK

## Logs
The in-app `FirebaseEvidenceLogger` prints lines starting with `🔥 [Firebase Evidence: <service>]`.
Capture them with:
```powershell
adb logcat -s flutter | Select-String "Firebase Evidence" | Out-File docs\evidence\evidence-log.txt
```
