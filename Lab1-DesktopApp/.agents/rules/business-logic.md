# Business logic — single source of truth

> Read `design/BUSINESS_REQUIREMENTS.md` fully before making any change. This file is
> the single source of truth for business logic and data generation — do not invent
> different rules elsewhere in the code.

Never re-derive these rules elsewhere in the code. If a page needs one of these
values, it **must** call `AttendanceStatsService` — do not write parallel logic.

## Entities (Google Sheet, snake_case, tab names lowercase)

```
students:   student_id, student_code, full_name, email, class_code, gender, major, photo_url
schedule:   session_id, class_code, subject_code, subject_name, session_date, slot, room, session_no, total_sessions
attendance: attendance_id, session_id, student_id, status, note, sync_status, updated_at
```

- `session_date` is stored as plain text `"yyyy-MM-dd"`. **Always** parse with
  `DateTime.parse()`; **never** compare as strings.
- `status`: `"present"` | `"absent"`. `sync_status`: `"draft"` | `"submitted"`.

## Derived rules (all implemented in `AttendanceStatsService`)

- **`isHeld(session)`** = `dateOnly(session.date) <= dateOnly(now)`.  
  A session is "held" only if its calendar date is today or earlier.  
  **Time-of-day and slot number do NOT matter for this check.**

- **`sessionStatus(session)`**:
  - `"not_taken"` if `!isHeld`
  - `"taken"` if `isHeld` && attendance rows exist for `session_id`
  - `"overdue_not_taken"` if `isHeld` && no attendance rows exist

- **`absenceRate(studentId, classCode)`**  
  = `count(absent rows where session isHeld)` / `count(all rows where session isHeld)`  
  for that student in that class. Returns `0` if denominator is `0`.

- **`studentStatus(rate)`**:
  - `"banned"` if `rate >= bannedThreshold` (default 20%)
  - `"warning"` if `rate >= warningThreshold` (default 15%)
  - `"ok"` otherwise

- Thresholds come from **Settings** (persisted via `SharedPreferences`), **never**
  hard-coded per page.

## Per-page rules

- **Home**: sessions where `date == today`, ordered by slot; stat cards from the shared
  service across ALL data, not just today.
- **Timetable**: sessions within the selected Mon–Sun week, colored by `sessionStatus`.
- **Take Attendance**: group by `subject_code`; cards ordered by `session_no`; badge =
  `sessionStatus`.
- **My Classes**: per class — student count, `classProgress = held/total` sessions,
  warning/banned counts via `studentStatus`.
- **Reports**: per class — sessions held, absent count, absence %, status; default sort
  by `%` desc.
- **Export**: CSV columns `student_code, full_name, class_code, session_date, slot, status`.
- **Any dropdown**: `items` and `value` must come from the same source list; never set a
  `value` not present in `items` — **disable the dropdown** (or clear the value) instead
  of crashing.
