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
already fixed in the working tree. Fill in the commit hash after you commit.

| # | Category | File / line (before) | Finding | Decision | Reason | Commit |
|---|---|---|---|---|---|---|
| S1 | Correctness | `lib/main.dart:44` | `PlatformDispatcher` undefined -> app and all tests failed to compile | Accept | Hard compile error | |
| S2 | Correctness | `firebase_auth_service.dart:91` | `GoogleSignInAuthentication.accessToken` does not exist in `google_sign_in` 7.x; error swallowed by `catch (_) {}` | Accept | Replace with `idToken` credential and explicit failure | |
| S3 | Security / honesty | `firebase_auth_service.dart` (fallback) | Failed Firebase sign-in still returned a hard-coded "Dr. Nguyen Van Minh" user, so a failed login looked successful and bypassed protection | Accept | Removed; typed `AuthException`, route guard added | |
| S4 | Correctness | `firebase_storage_service.dart` | Fake download URL + `public_reports` uid when upload/auth failed; success logged anyway | Accept | Evidence must be real; now throws `StorageFailure` | |
| S5 | Correctness | `firebase_messaging_service.dart` | Invented FCM token `fcm_token_attendEase_…`; no `onMessageOpenedApp` / `getInitialMessage`; history not stored | Accept | Required by guide (3 app states, history, tap routing) | |
| S6 | Reliability | `google_sign_in` init | `GoogleSignIn.initialize()` allowed only once, was called from the Sheets service; a second caller would throw | Accept | Shared `GoogleSignInBootstrap` | |
| S7 | Architecture | `lib/main.dart` | `GoRouter` created inside `build()`; ViewModels recreated on every route rebuild | Accept | Router in `State`; Provider owns ViewModel lifecycle | |
| S8 | Privacy | `ai_assistant_viewmodel.dart:201`, auth/profile/header | Student id sent as an Analytics parameter; emails written to the evidence log; hard-coded lecturer name in header | Accept | Guide forbids PII in parameters | |
| S9 | Maintainability | all Firebase services | Shadow writes to Firestore (`analytics_events`, `crashlytics_reports`, `storage_reports`, `remote_config`) hid real SDK failures and used an unlisted service | Accept | Removed; `cloud_firestore` dropped | |
| S10 | Correctness | `firebase_analytics_service.dart` | `screen_view` and `login` were logged twice (SDK helper + custom event) | Accept | One event per action in DebugView | |
| S11 | UX | `settings_page.dart` | Crash button fired immediately and claimed success | Accept | Confirmation dialog; guide forbids accidental crashes | |
| S12 | Correctness | `login_page.dart:205` | Row overflow on narrow phones | Accept | `Flexible` text | |

## 2. Findings from the PR review tool (fill in)

Tool: __________  PR: __________  Date: __________

| # | Category | File:line | Tool comment (quote) | Decision (accept / modify / reject) | Technical reason | Commit |
|---|---|---|---|---|---|---|
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |
| 4 | | | | | | |
| 5 | | | | | | |

Categories used (>= 2): ______________________

## 3. Summary for the report

* Findings: ___ total; accepted ___, modified ___, rejected ___.
* Fixed with commits: ___ (>= 3 required).
* One finding you rejected and why: ______________________________________
