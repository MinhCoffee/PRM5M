# ARTEMIS end-to-end test plan (Lab 3)

Requirements from the Lab 3 guide this file covers:

* >= **10 cases**: precondition, steps, expected result.
* Cover the **3 Lab 2 user flows** (Authentication, Take Attendance, View Reports),
  **one error branch**, and **one native Android interaction**.
* Every Firebase service has an error case (see section C).
* Run each case **>= 3 times**; report pass rate and keep the execution log.
* Verify **observed values**, not just a `SUCCESS` status.
* One exploratory session of **15-30 minutes**.

> Environment prerequisites (Python 3.12+, `uv`, ADB, multimodal model API key)
> are in the guide. Keep the API key in an environment variable or an ignored
> `.env`; never commit it. The ARTEMIS tool itself is not part of this repo —
> follow its own documentation for how to feed it these cases.

Package: `com.example.flutter_application_1` · Device: __________ · Android: ____

## A. Test cases

Test account: a dedicated Google test user that has Editor access to the sheet and
sample data seeded (Settings -> *Seed sample data*).

| ID | Flow / type | Precondition | Steps | Expected (observable) |
|---|---|---|---|---|
| TC-01 | Auth (happy) | Signed out, online | Open app -> tap **Sign in with Google** -> choose test account | Home screen visible; header shows the account's display name; Profile shows the same uid as Firebase Console |
| TC-02 | Auth (**error branch**) | Signed out | Tap sign in -> **Cancel** the Google account picker | Still on login; message contains "hủy đăng nhập"; no crash dialog; **Retry/Sign in** button still enabled |
| TC-03 | Auth (protection) | Signed in | Settings/Header -> **Đăng xuất** -> press Back | Login screen stays; Home content not shown |
| TC-04 | Take Attendance (happy) | Signed in, a session today | Take Attendance -> open a session -> mark 2 students absent -> **Save draft** | Success feedback; counters show `Present = N-2`, `Absent = 2`; reopening the session shows the same two absent |
| TC-05 | Take Attendance (submit) | TC-04 state | Tap **Submit** | Status chip becomes "submitted/Đã nộp"; Home "Ca đang lưu nháp" decreases by 1; re-submitting does not create duplicate rows |
| TC-06 | Take Attendance (**error recovery**) | Signed in | Enable airplane mode -> change statuses -> Save | Error message "Lỗi kết nối khi lưu…"; selections unchanged; **Retry** visible; disable airplane mode -> Retry -> success |
| TC-07 | View Reports (happy) | Data seeded | Reports -> choose class `SE1801` | Table/cards list students; absent % values equal the Home/AI Assistant numbers for the same student |
| TC-08 | View Reports + Storage | Online, signed in | Reports -> **Export CSV** -> save | Local file saved; banner shows progress then "Đã sao lưu…reports/<uid>/…"; URL copyable; file exists in Cloudinary Media Library |
| TC-09 | **Native Android** | Fresh install | Launch app; Android 13+ permission dialog for notifications | System dialog appears; **Allow** -> Notification centre has no "từ chối" banner; **Deny** (second run) -> banner "đã từ chối quyền" shown |
| TC-10 | FCM (3 states) | Token copied from Profile | Send Console test message with `data.route=/reports` while app is foreground, background, terminated | Foreground: item appears in Notification centre + badge; background/terminated: tapping the system notification opens **Reports** |
| TC-11 | Remote Config (observable change) | Home shows banner and >1 session | Console: `show_banner=false`, `max_items=1` -> Publish -> Home refresh | Banner hidden; list shows 1 session and text `1/N ca (giới hạn max_items = 1)` |
| TC-12 | Crashlytics (handled + test) | Signed in | Settings -> **Non-fatal**; then Settings -> **Test crash** -> confirm -> reopen | Non-fatal visible in Console; fatal crash appears with user id + custom keys `test_origin`, `intentional_test_crash` |

### C. Error case per Firebase service (guide checklist, slide 25)

| Service | Error case | Covered by |
|---|---|---|
| Authentication | User cancels / offline | TC-02, evidence checklist §1 |
| Cloud Storage | Offline upload and wrong preset rejected | TC-08 variant (airplane mode) + invalid preset in .env |
| Cloud Messaging | Permission denied | TC-09 (Deny run) |
| Analytics | Offline: app keeps working, events flush later | exploratory + checklist §4 |
| Crashlytics | Handled error shows a user-facing message | TC-06 (save error is recorded + shown) |
| Remote Config | Fetch fails -> defaults/cached values | checklist §6 (airplane mode) |

## B. Execution log (fill in; do not pre-fill)

| ID | Run 1 | Run 2 | Run 3 | Pass rate | Observed value checked | Log file |
|---|---|---|---|---|---|---|
| TC-01 | | | | /3 | | |
| TC-02 | | | | /3 | | |
| TC-03 | | | | /3 | | |
| TC-04 | | | | /3 | | |
| TC-05 | | | | /3 | | |
| TC-06 | | | | /3 | | |
| TC-07 | | | | /3 | | |
| TC-08 | | | | /3 | | |
| TC-09 | | | | /3 | | |
| TC-10 | | | | /3 | | |
| TC-11 | | | | /3 | | |
| TC-12 | | | | /3 | | |

Overall pass rate: ____ / ____ = ____ %

Flaky or failing cases: describe cause (app bug vs test bug) and the fix.

## D. Exploratory session (15-30 min)

* Start / end time: ________ -> ________ (duration ____ min)
* Charter: try to break sign-out, offline saves and notification taps.
* Findings (bug, severity, steps, evidence):
  1.
  2.
