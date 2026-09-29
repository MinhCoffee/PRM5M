# Data seeding rules

> Read `design/BUSINESS_REQUIREMENTS.md` fully before touching seed logic.

All rules below must be followed when generating sample data in `seedSampleData()`.

## Behavior

- **Full replace**: seeding FIRST clears all data rows (keeps header) in students,
  schedule, and attendance tabs, then generates a completely fresh randomized dataset.
- No manual sheet editing should ever be required.
- Running seed twice gives a fresh consistent dataset each time.
- A **confirmation dialog** must be shown before deleting old data.
- A **snackbar** with a summary (subjects, classes, students, sessions) must be shown
  when complete.

## Core constraints

1. **Anchor to real current date** — use `DateTime.now()`. Never use a fixed date.
2. **30 sessions per class**, on a fixed weekly pattern (e.g. Mon + Thu), spanning
   **both past and future** relative to today:
   - 40–60 % of sessions dated **in the past** (`isHeld = true`)
   - The rest dated **today or in the future** (`isHeld = false`)
   - `session_no` must increase in chronological order (`session_no=1` is earliest)
3. **Attendance rows only for `isHeld == true` sessions** — never for future sessions.
4. **Target absence profiles** (decided per student per class, not per-row random):
   - ~70 % of students: 0–10 % absence → status `"ok"`
   - ~15 %: 15–19 % absence → status `"warning"`
   - ~15 %: 20 %+ absence → status `"banned"` (e.g. 20–35 %)
   Compute how many of a student's held sessions should be `"absent"` (round to
   nearest int), then mark that many absent. Use randomness **within** each band
   so numbers aren't identical every run.
5. `sync_status = "submitted"` for all seeded attendance rows. Never `"draft"`.
6. **Randomized data**: 3–5 subjects, 2–3 classes each, 15–30 students per class,
   Vietnamese full names generated with variety, mixed gender, ~10–20 % cross-enrolled
   from another major.
7. IDs must be unique within the sheet but no special prefix is required.

## What NOT to do

- Do not generate `startDate = today - 14 days` and add `sessionNo - 1` days —
  that produces 30 consecutive calendar days, not a realistic weekly schedule.
- Do not use strict `date.isBefore(today)` to decide which sessions get attendance;
  use `dateOnly(date) <= dateOnly(today)` (i.e. today's sessions also get attendance).
- Do not assign absence by `sessionNumber % N == 0` — that is pure random and ignores
  the required absence profile distribution.
- Do not attempt idempotent skip-if-exists — always clear and regenerate.
