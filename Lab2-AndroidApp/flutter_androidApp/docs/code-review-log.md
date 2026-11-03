# AI code review log (Lab 3)

Guide requirements: review **one pull request** with Copilot, CodeRabbit or an
equivalent tool; record **>= 5 findings** tied to code lines from **>= 2
categories**; accept / modify / reject **each** with a technical reason; **fix
>= 3 accepted findings with traceable commits**.

## How to produce the official review

1. Push the work on a branch (e.g. `lab3-firebase`) and open a PR to `main`.
2. Request the AI review on that PR (Copilot review / CodeRabbit).
3. Copy each comment into the table in section 2 and decide.
4. Fix at least 3 accepted ones, one commit per finding, and paste the commit hash.

## 1. Pre-PR self-review by Claude Code (input, not a substitute for step 2)

These issues were found by reading the code before the Lab 3 rework and are
already fixed in PR #1 (branch `lab3-firebase`); the Commit column links each
finding to the commit that fixed it.

| # | Category | File / line (before) | Finding | Decision | Reason | Commit |
|---|---|---|---|---|---|---|
| S1 | Correctness | `lib/main.dart:44` | `PlatformDispatcher` undefined -> app and all tests failed to compile | Accept | Hard compile error | e8c698f |
| S2 | Correctness | `firebase_auth_service.dart:91` | `GoogleSignInAuthentication.accessToken` does not exist in `google_sign_in` 7.x; error swallowed by `catch (_) {}` | Accept | Replace with `idToken` credential and explicit failure | 66c1502 |
| S3 | Security / honesty | `firebase_auth_service.dart` (fallback) | Failed Firebase sign-in still returned a hard-coded "Dr. Nguyen Van Minh" user, so a failed login looked successful and bypassed protection | Accept | Removed; typed `AuthException`, route guard added | 66c1502 |
| S4 | Correctness | `firebase_storage_service.dart` | Fake download URL + `public_reports` uid when upload/auth failed; success logged anyway | Accept | Evidence must be real; now throws `StorageFailure` | 7cf0c58 |
| S5 | Correctness | `firebase_messaging_service.dart` | Invented FCM token `fcm_token_attendEase_…`; no `onMessageOpenedApp` / `getInitialMessage`; history not stored | Accept | Required by guide (3 app states, history, tap routing) | 4b1cc6e |
| S6 | Reliability | `google_sign_in` init | `GoogleSignIn.initialize()` allowed only once, was called from the Sheets service; a second caller would throw | Accept | Shared `GoogleSignInBootstrap` | 66c1502 |
| S7 | Architecture | `lib/main.dart` | `GoRouter` created inside `build()`; ViewModels recreated on every route rebuild | Accept | Router in `State`; Provider owns ViewModel lifecycle | e8c698f |
| S8 | Privacy | `ai_assistant_viewmodel.dart:201`, auth/profile/header | Student id sent as an Analytics parameter; emails written to the evidence log; hard-coded lecturer name in header | Accept | Guide forbids PII in parameters | 66c1502, 4b1cc6e, 81636bc |
| S9 | Maintainability | all Firebase services | Shadow writes to Firestore (`analytics_events`, `crashlytics_reports`, `storage_reports`, `remote_config`) hid real SDK failures and used an unlisted service | Accept | Removed; `cloud_firestore` dropped | 7cf0c58, 81636bc |
| S10 | Correctness | `firebase_analytics_service.dart` | `screen_view` and `login` were logged twice (SDK helper + custom event) | Accept | One event per action in DebugView | 81636bc |
| S11 | UX | `settings_page.dart` | Crash button fired immediately and claimed success | Accept | Confirmation dialog; guide forbids accidental crashes | 81636bc |
| S12 | Correctness | `login_page.dart:205` | Row overflow on narrow phones | Accept | `Flexible` text | 66c1502 |

## 2. Findings from the PR review tool

Tool: Claude Code `/code-review` (effort medium), diff `main..lab3-firebase`.
GitHub Copilot was requested on PR #1 but did not review it ("insufficient
remaining quota"), and PR #1 was merged before a review ran, so this review ran
locally on the three follow-up commits (b7059aa, aac0950, 5495b40).
PR: [... new PR link once opened ...]   Date: 2026-11-03

| # | Category | File:line | Finding (tool output, summarised) | Decision | Technical reason | Commit |
|---|---|---|---|---|---|---|
| 1 | Reliability | `lib/core/models/cloud_backup_mixin.dart:57` | An upload can outlive its route; progress/completion call `notifyListeners()` on a disposed view model ("ChangeNotifier used after being disposed") | Accept | Provider disposes the view model on route exit while the upload continues | d8c0dbb |
| 2 | Correctness | `lib/core/models/cloud_backup_mixin.dart:57` | No re-entrancy guard: a second Export tap overwrites `_pending` and interleaves progress, so Retry can resend the wrong file | Accept | Early return while `isBackingUp` | d8c0dbb |
| 3 | Reliability | `lib/core/services/firebase/firebase_storage_service.dart:138` | `task.timeout(60s)` throws but does not stop the transfer; a retry races the first upload to the same path | Accept | Cancel the task on `TimeoutException` | 03a2251 |
| 4 | Security | `lib/core/services/firebase/firebase_messaging_service.dart:476` | `routeForNotification` trusts any `data['route']` starting with `/`; `/login?logout=1` signs the user out on tap | Modify | Rejecting `//` and `/login*` closes the reported case; a full allow-list of known routes would be stricter but changes behaviour | f6c4406 |
| 5 | Correctness | `firebase_messaging_service.dart:628` | `_persist()` rewrites the whole in-memory history and can drop pushes saved by the background isolate | Accept, not fixed yet | Needs merge-on-persist, a behaviour change beyond a local patch | [...] |
| 6 | Security / identity | `lib/services/google_sheet_service.dart:903` | `attemptLightweightAuthentication()` may return a cached account different from the one Firebase just signed in with | Accept | Compare the account email with the Firebase user; fall back to the chooser, then fail with a clear message; introduced by aac0950 | 49a80ec |
| 7 | Performance | `lib/features/home/viewmodel/home_viewmodel.dart:63` | `loadDashboard` awaits `fetchAndActivate()` (10s timeout) before loading stats | Accept, not fixed yet | Fetch in parallel or in the background | [...] |
| 8 | Maintainability | `android/app/google-services.json` | Untracked and not git-ignored; a blanket `git add` could commit it | Accept | CLAUDE.md says the file is added manually per developer | 0d669a3 |
| 9 | Maintainability | `windows/flutter/generated_plugins.cmake`, macOS registrant | `flutter pub get` rewrites generated registrants for platforms nobody builds | Accept | Reverted with `git checkout`; no code change | (none) |

Categories used (>= 2): Reliability, Correctness, Security, Performance, Maintainability.

## 3. Summary for the report

* Findings: 9 total; accepted 8, modified 1 (#4), rejected 0.
* Fixed with commits: 6 findings (#1, #2, #3, #4, #6, #8) in 5 commits (>= 3 required). #9 needed no commit.
* Open (accepted, not yet fixed): #5, #7.
* One finding you rejected and why: [... none rejected so far; fill in if you reject one ...]
