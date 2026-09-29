# Coding standards

## Dart / Flutter

- Use `DateTime.parse(dateString)` (or `DateTime.tryParse`) for all date parsing.
  Never compare `session_date` strings lexicographically.
- Use `DateUtils.dateOnly(date)` (or `DateTime(y, m, d)`) to strip time before
  comparing dates. Do **not** include time-of-day or slot in "is this date held?"
  logic.
- All attendance statistics must go through `AttendanceStatsService`. Pages must not
  duplicate any of its calculation logic.
- `DropdownButton` / `DropdownButtonFormField`: the `value` must always be an element
  of the `items` list. When the list is empty or the previous value is no longer
  present, **set `value = null` and `enabled = false`** rather than letting Flutter
  throw an assertion error.
- Do not hard-code thresholds (15 %, 20 %). Always read from
  `AttendanceStatsService.warnThreshold` / `.banThreshold`.

## File organisation

- One feature per folder under `lib/features/`.
- Shared services live in `lib/services/`.
- Models live in `lib/models/`.
- No business logic in widget `build()` methods — extract to service or helper.

## Git

- Commit messages: `<type>(<scope>): <short description>` (conventional commits).
- Never commit `.env` or OAuth credential files.
