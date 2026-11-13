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

Package: `com.example.flutter_application_1` · Device: Android Emulator `Medium_Phone_API_37.0` (API 37, x86_64) · ARTEMIS flash profile, model `gemini-3.5-flash-lite`

## A. Test cases

Test account: a dedicated Google test user that has Editor access to the sheet and
sample data seeded (Settings -> *Seed sample data*).

| ID | Flow / type | Precondition | Steps | Expected (observable) |
|---|---|---|---|---|
| TC-01 | Auth (happy) | Signed out, online | Open app -> tap **Sign in with Google** -> choose test account | Home screen visible; header shows the account's display name; Profile shows the same uid as Firebase Console |
| TC-02 | Auth (**error branch**) | Signed out | Tap sign in -> **Cancel** the Google account picker | Still on login; message contains "hủy đăng nhập"; no crash dialog; **Retry/Sign in** button still enabled |
| TC-03 | Auth (protection) | Signed in | Settings/Header -> **Đăng xuất** -> press Back | Login screen shown; pressing Back does not reveal Home content. **Observed:** Back on the login screen closes the app (goes to the launcher) instead of staying on login; Home is never shown |
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

## B. Execution log

Source of truth: `D:/8th_semester/PRM393/Lab01/tools/artemis-runs/results.jsonl` (one JSON row per run) plus
`<ID>-run<N>.log` / `.png` per run in the same folder (outside this repo; copy the folder into the submission).
A run counts as PASS only if ARTEMIS completed **and** the harness's observed-value check passed (values are read from
the app and compared; ARTEMIS "success" alone is not enough). Everything below is copied from those rows.

| ID | Runs (chronological) | Pass rate | Observed value checked | Log file |
|---|---|---|---|---|
| TC-01 | PASS, PASS, PASS, FAIL, PASS | 4/5 | Home reached; display name "Anh Anh"; Profile UID starts `SJ8Dq9rFu2ZO` (matches Firebase Console) | `TC-01-run1..3.log` |
| TC-02 | PASS, PASS, PASS, FAIL | 3/4 | Message "Bạn đã hủy đăng nhập Google…", sign-in button enabled, on login, no crash dialog | `TC-02-run1..3.log` |
| TC-03 | PASS, PASS, FAIL, FAIL, PASS, PASS | 4/6 | After logout: login screen; after Back: adb shows the launcher (not the app) in focus. The last two runs use the adb check; the first four asked ARTEMIS whether Home content was visible | `TC-03-run1..3.log` |
| TC-04 | PASS, FAIL, PASS, PASS, PASS | 4/5 | Summary line Present = N-2 / Absent = 2; reopen shows 2 absent. Runs 3-5 use classes SE1802, SE1809, SE1805 | `TC-04-run1,2,4,5,6.log` |
| TC-05 | FAIL, FAIL, PASS, PASS, PASS | 3/5 | Card "Completed" and "Ca đang lưu nháp" counter decreases by 1 (5 -> 4 in each passing run). Runs 3-5 use SE1802, SE1809, SE1805 | `TC-05-run0,2,4,5,6.log` |
| TC-06 | PASS, PASS, PASS, PASS | 4/4 | Offline error banner, Retry visible, first student still absent, banner gone after Retry | `TC-06-run0,4,5,6-*.log` |
| TC-07 | PASS, PASS, PASS | 3/3 | HE176571, class SE1801, "Vắng 2/4 buổi" = 50.0 %, all cards SE1801 | `TC-07-run1..3.log` |
| TC-08 | PASS, PASS, PASS | 3/3 | Banner path `reports/SJ8Dq9rFu2ZO…` and `res.cloudinary.com/i3ywvfws…` URL | `TC-08-run1..3.log` |
| TC-09 | PASS ×3 (Allow), PASS ×3 (Deny) | 6/6 | Dialog seen; Allow -> no "từ chối" banner; Deny -> banner shown | `TC-09a/09b-run1..3.log` |
| TC-10 | not run with ARTEMIS | n/a | Needs Console test message and a terminated app; covered manually, see `firebase-evidence-checklist.md` | n/a |
| TC-11 | not run with ARTEMIS | n/a | Needs a Console Publish (Remote Config publish is not done: Blaze banner); see checklist | n/a |
| TC-12 | PASS, PASS, PASS | 3/3 | Non-fatal feedback text shown; process PID changes after the test crash | `TC-12-run1..3.log` |

Overall (ARTEMIS-executed cases): **37 PASS / 44 runs = 84.1 %**. Runs listed above are counted strictly, including failures
caused by the test harness. Every case above now has at least 3 runs and at least 3 PASS, except where noted in the list below.

### Flaky or failing cases (cause: app bug vs test bug)

* **TC-01 run 3 (FAIL)**: ARTEMIS stayed on "Đang xác thực Google…" and the log shows `device offline`. Probably the
  emulator under RAM pressure; not confirmed. Runs 1, 2 and 4 passed.
* **TC-02 run 3 (FAIL)**: test bug (parser now accepts both formats; this case was not re-run). ARTEMIS returned the correct values but as `KEY: value` instead of `KEY=value`, so the
  harness parsed nothing. App behaved correctly.
* **TC-03 runs 3 and 4 (FAIL)**: ARTEMIS reported `HOME_CONTENT_VISIBLE=true` while it was on the launcher
  (`AFTER_BACK_SCREEN=launcher`). Test bug (misread question). Fixed by an adb check of the focused window; the last two runs pass with it.
  Real finding: **Back on the login screen exits the app**, whereas the case text expected it to stay on login.
* **TC-04 run 2 (FAIL)**: data-state problem (test precondition, not an app bug). Session SE1808 had been submitted earlier and no longer appeared under "Ca học hôm nay", so ARTEMIS could not open it. Fixed by using a different class that still has a pending session for each run (SE1802, SE1809, SE1805); runs 3-5 pass. It is not confirmed whether the app hides completed sessions by design.
* **TC-05 runs 1-2 (FAIL)**: same cause: SE1808 was already submitted, so the "Ca đang lưu nháp" counter had nothing to decrease (run 1: 2 -> 2; run 2: 4 -> 4, although the success message and "Completed" card were seen). With a fresh class after TC-04 saved its draft, the counter drops 5 -> 4 in all three runs. Not checked: that re-submitting never creates duplicate rows in the Sheet.
* **TC-04 / TC-05 toast**: the success toast after Lưu nháp / Nộp is captured in only some runs (`msg=NONE` otherwise). The PASS verdict rests on counters, card status and reopening the session, not on the toast.
* **TC-06 (PASS, weak check)**: uses class SE1812 (NWC203) in every run; the red banner "LỖI KẾT NỐI - ĐÃ SAO LƯU BẢN NHÁP CỤC BỘ" is the expected result of saving in airplane mode. After Retry, ARTEMIS did not capture a success message
  (`RESULT_TEXT=NONE`); PASS rests only on the error banner disappearing, not on checking the row in the Sheet.

### Runs excluded from the table (kept in the logs)

* Pilots (`run` = 0) of TC-03, TC-07 and TC-12 are not counted. The `run` = 0 rows of TC-05 (FAIL) and TC-06 (PASS) **are** counted in the table, because they were the first runs of the corrected tests.
* Early attempts of TC-05 (run 1), TC-06 (run 1) and TC-12 (run 1) failed because of **test design bugs** (SE1808 card not on Home;
  airplane mode enabled before the session opened; wrong process-died check). The tests were corrected afterwards.
* TC-12 run 1 of the old script is replaced by the three runs with the corrected check.
* `invalid-environment-failures.jsonl`: 6 attempts that failed because the emulator was offline or the API quota ran out;
  they say nothing about the app.

Data changed by the runs: attendance rows for SE1807/SE1808 sessions in the Google Sheet, and extra CSV files in Cloudinary `reports/`.

## D. Exploratory session (15-30 min)

Charter: try to break sign-out, offline saves and notification handling. Run by ARTEMIS as an open-ended goal (no fixed steps; the app was locked to the package).
Logs: `EXPLORE-1.log`, `EXPLORE-2.log`, `EXPLORE-3.log` and `explore-results.jsonl` in the `artemis-runs` folder (outside this repo).

| ARTEMIS run | Start (local) | Active time | Steps / LLM calls | Outcome |
|---|---|---|---|---|
| EXPLORE-1 | 11:46 | 8.9 min | 26 / 55 | Stopped by the daily API quota; no report (not counted) |
| EXPLORE-2 | 12:06 | 8.7 min | 69 / 148 | Completed, 6 areas covered |
| EXPLORE-3 | 12:17 | 6.8 min | 37 / 113 | Completed, 10 areas covered (4 extra areas) |

**Duration caveat:** ARTEMIS finishes an exploration quickly, so a single run never reached 15 minutes. The counted session is EXPLORE-2 followed by
EXPLORE-3: about 15.5 min of active ARTEMIS time and about 18 min on the clock (12:06 to 12:24). It is two consecutive runs, not one continuous run.
Both runs wrote to the live Sheet (attendance for class SE1812).

Findings (as reported by ARTEMIS; only item 1 has independent evidence):

1. **[medium] Raw network error text when opening attendance offline.** With airplane mode on, opening the Điểm danh tab or a session shows
   `Không thể tải dữ liệu ca điểm danh: Could not read schedule: ClientException with SocketException: Failed host lookup: 'sheets.googleapis.com'`
   instead of a friendly message or cached data. Also seen in the first TC-06 run (`results.jsonl`). The app does not support opening a session offline.
2. **[unverified] "Access was denied" / `invalid_token` error card** while loading the schedule (EXPLORE-3 only). Not reproduced by me; could be an expired Google token after sign-out/sign-in. Needs a manual check.
3. **[info] Back on the login screen exits the app** (EXPLORE-2); consistent with TC-03.
4. Sign-out and sign-in again, notification centre actions (mark as read, clear all), rapid taps and tab switching, Settings (thresholds untouched, Test Crash not pressed),
   Reports class filter, AI assistant and Profile: ARTEMIS reported no defect.

Not covered: tapping a **system** push notification (needs a Console message), so notification taps from the tray were not explored. EXPLORE-3 item 10 (unsaved changes lost when leaving a session) was reported without a clear observation, so no conclusion is drawn.
