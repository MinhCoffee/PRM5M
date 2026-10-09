# Firebase Email Notifications

The Flutter app automatically detects missing attendance and `warning`/`banned` students when the AI Assistant loads. It sends new risk events to `ATTENDANCE_NOTIFICATION_ENDPOINT`.

## Required configuration

1. Create a Firebase project and enable Authentication and Firestore.
2. Deploy a protected HTTPS or callable Cloud Function for the endpoint.
3. Configure SendGrid, Resend, or Mailgun in the function. Gmail API is possible but needs additional OAuth configuration.
4. Store the provider API key with Firebase Functions secrets, never in Flutter `.env`.
5. Set these Flutter variables:

```env
ATTENDANCE_NOTIFICATION_ENDPOINT=https://<region>-<project>.cloudfunctions.net/attendanceNotification
ATTENDANCE_TEACHER_EMAIL=lecturer@university.edu
```

## Request contract

The function receives JSON in this shape:

```json
{
  "type": "attendance_risk_alert",
  "teacher_email": "lecturer@university.edu",
  "recipients": [
    {
      "email": "student@university.edu",
      "student_id": "S001",
      "student_code": "SE1801",
      "full_name": "Student Name",
      "status": "warning",
      "absence_rate": 0.16,
      "absent_count": 4,
      "sessions_held": 25
    }
  ],
  "missing_sessions": [
    {
      "session_id": "SESSION_001",
      "subject_code": "PRM391",
      "class_code": "SE1801",
      "session_date": "2026-10-01",
      "status": "Missing Attendance"
    }
  ]
}
```

## Cloud Function responsibilities

- Verify Firebase Authentication and the lecturer role.
- Send one personalized email per recipient.
- Send one digest reminder to `teacher_email` for missing sessions.
- Store an idempotency record in Firestore, such as `notification_events/{student_id}_{status}_{absence_rate}`.
- Return HTTP 2xx only after the provider accepts the messages.
- Reject unauthenticated requests and invalid email addresses.

The current Flutter fallback stores sent event keys locally. After the Firebase migration, Firestore must become the source of truth because lecturers can use multiple devices.