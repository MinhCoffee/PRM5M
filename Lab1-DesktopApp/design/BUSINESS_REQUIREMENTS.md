# FAP Attendance — Business Requirements (source of truth)

## Entities (Google Sheet, snake_case, tab names lowercase)

students: student_id, student_code, full_name, email, class_code, gender, major, photo_url
schedule: session_id, class_code, subject_code, subject_name, session_date, slot, room, session_no, total_sessions
attendance: attendance_id, session_id, student_id, status, note, sync_status, updated_at

- session_date format: "yyyy-MM-dd" stored as plain text. All date comparisons in code
  must parse with DateTime.parse(session_date) — never string-compare.
- status: "present" | "absent". sync_status: "draft" | "submitted".

## Core derived rules (implement ONCE in AttendanceStatsService, every page reuses it)

- `isHeld(session)` = DateUtils.dateOnly(session.date) <= DateUtils.dateOnly(now).
  A session is "held" only if its calendar date is today or earlier. Time-of-day/slot
  does not matter for this check.
- `sessionStatus(session)`:
  - "not_taken" if isHeld == false
  - "taken" if isHeld == true AND attendance rows exist for this session_id
  - "overdue_not_taken" if isHeld == true AND no attendance rows exist
- `absenceRate(studentId, classCode)` = count(attendance rows where student_id matches
  AND status=absent AND session isHeld) / count(attendance rows where student_id matches
  AND session isHeld). If denominator is 0, rate = 0 and status = "ok".
- `studentStatus(rate)`:
  - "banned" if rate >= bannedThreshold (default 20%)
  - "warning" if rate >= warningThreshold (default 15%)
  - "ok" otherwise
- Thresholds are read from Settings (persisted), not hard-coded, and every page must
  use the same source.

## Data generation rules for "Seed sample data" (must produce a REALISTIC dataset)

1. Anchor everything to the real current date (DateTime.now()), never to a fixed date.
2. For each class, generate exactly `total_sessions` (30) schedule rows, meeting on a
   fixed weekly pattern (e.g. every Mon+Thu for that class), spanning both PAST and
   FUTURE relative to today:
   - Roughly 40-60% of sessions dated in the past (isHeld = true)
   - The rest dated today or in the future (isHeld = false)
   - session_no must increase in chronological order (session_no=1 is the earliest date)
3. Attendance rows are generated ONLY for sessions where isHeld == true. Never create
   attendance rows for future sessions.
4. For each student, assign a target absence profile so the dataset is testable:
   - ~70% of students: 0-10% absence (status "ok")
   - ~15%: 15-19% absence (status "warning")
   - ~15%: 20%+ absence (status "banned", e.g. one clearly at 25-35%)
   Apply this by deciding, per student per class, how many of their held sessions are
   "absent" (round to nearest integer), not by pure random chance per row.
5. sync_status = "submitted" for all seeded past sessions (simulates already-taken
   attendance); never "draft" for seed data, so seed data behaves like real finalized
   records.
6. IDs must never collide with real/manual data: prefix all seeded IDs with "SAMPLE-"
   (already the convention in use) and the seed operation must be idempotent — running
   it twice must not duplicate rows (skip if a SAMPLE- row with the same key exists).
7. Use varied but plausible Vietnamese full names, gender split roughly even, major
   mostly the class's expected major with ~15% cross-enrolled from another major
   (already implemented correctly per the current students tab — keep this).

## Per-page requirements (must all read from AttendanceStatsService, no separate logic)

- Home: sessions where session.date == today (exact calendar date match), ordered by
  slot; 4 stat cards computed from the shared service across ALL classes/sessions,
  not just today.
- Timetable: sessions where session.date falls within the selected week (Mon-Sun),
  colored by sessionStatus.
- Take Attendance browse: group by subject_code, one row per subject, cards = all
  sessions of each class ordered by session_no; badge on each card = sessionStatus.
  "Today's sessions" section = sessions where isHeld status makes sense to show first
  (e.g. session.date == today), not just "first N by session_no".
- My Classes: per class_code, students count, classProgress = held sessions / total,
  warning count and banned count computed via studentStatus for every student in that
  class.
- Reports: per selected class, one row per student with sessions held (denominator
  above), absent count, absence %, status; sortable, default sort by % desc.
- Export: CSV of attendance rows for a selected class/date range, columns
  student_code, full_name, class_code, session_date, slot, status.
- AI Assistant: canned questions computed from the shared service; any dropdown must
  build its `items` list and `value` from the SAME source list (no separate queries),
  and must handle the "no items yet" case by disabling the dropdown instead of setting
  a value that isn't in the list.
