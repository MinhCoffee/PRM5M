# FAP Attendance

Flutter Windows desktop attendance application using Google Sheets as the data store.

## Implemented flow

- Google OAuth Desktop user login.
- Load sessions from the `schedule` sheet.
- Load students by `class_code` from `students`.
- Load existing attendance from `attendance`.
- Mark students present or absent.
- Edit attendance notes.
- Save draft records.
- Submit records without duplicating the same `session_id` + `student_id` pair.
- Search and filter large student rosters by name, roll number, and status.
- Create clearly marked sample data from the session browser after confirmation.
- Reuse the OAuth refresh token from the local application-support directory when available.

The navigation items for Home, My Classes, Timetable, Reports, FAP Sync, AI Assistant, and Settings are placeholders and are not part of the completed attendance flow.

## Requirements

- Windows 10/11.
- Flutter SDK compatible with Dart `^3.13.3`.
- Visual Studio with the Desktop development with C++ workload.
- A Google Cloud project with the Google Sheets API enabled.
- An OAuth client of type **Desktop app**.

## Configuration

Create `.env` in the project root. The file is ignored by Git, but must be included when sharing a ZIP:

```env
GOOGLE_CLIENT_ID=your-desktop-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-desktop-client-secret
GOOGLE_SPREADSHEET_ID=your-spreadsheet-id
ATTENDANCE_NOTIFICATION_ENDPOINT=https://your-cloud-function-url
ATTENDANCE_TEACHER_EMAIL=lecturer@university.edu
```

The Google account used during login must have Editor access to the spreadsheet. OAuth opens the browser and receives the callback through a local port; no manual redirect URI is required for a Desktop OAuth client.

The notification endpoint must be a protected Firebase Cloud Function (or equivalent backend) that validates the signed-in lecturer before sending email. Keep email provider API keys and Gmail credentials in Firebase Functions secrets, never in the Flutter `.env` file.

## Required sheet tabs and headers

The spreadsheet must contain normal Google Sheets tabs named exactly `students`, `schedule`, and `attendance`. Row 1 must contain the headers defined in the project specification. The app reports missing tabs or columns instead of silently using fallback data. The **Seed sample data** action only appends missing `SAMPLE-` rows and never overwrites existing attendance rows.

## Run and validate

From this directory:

```powershell
flutter pub get
flutter analyze lib
flutter test
flutter run -d windows
```

To create a Windows build:

```powershell
flutter build windows
```

Do not include `.dart_tool`, `build`, or generated cache folders in a source ZIP. Keep `.env` only when the recipient is authorized to use the configured Google spreadsheet, and rotate any OAuth secret that has been exposed.# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
