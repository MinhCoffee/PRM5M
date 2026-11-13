# Firebase setup checklist (manual steps the code cannot do for you)

The code is ready; these steps need **your** Firebase / Google account. Do them
in order. Nothing here should be committed except where stated.

## 0. Prerequisites

* Windows **Developer Mode** on (`start ms-settings:developers`), otherwise
  `flutter pub get` warns about symlinks.
* Android emulator with Google Play (for Google Sign-In + FCM) or a real device.
* A *test* Google account (do not use a personal one for the demo).

## 1. Project and Android app

1. Firebase Console -> create/open your project (the code references bucket
   `fap-attendance-85250` in older notes; use whichever project you own).
2. **Add app -> Android**, package name **`com.example.flutter_application_1`**
   (must equal `applicationId` in `android/app/build.gradle.kts`; if you rename
   the package, change it in both places *before* registering).
3. Add SHA fingerprints (needed for Google Sign-In):
   ```powershell
   cd android
   .\gradlew signingReport      # copy SHA-1 and SHA-256 of the "debug" variant
   ```
   Firebase Console -> Project settings -> Your apps -> *Add fingerprint*.
4. Download **`google-services.json`** and place it at
   `android/app/google-services.json`.
   Without it the Gradle build fails (the Google Services plugin is applied).
   The file holds client identifiers, not server secrets, but keep it consistent
   with your team's policy; never commit service-account keys or `.env`.

(Alternative: `dart pub global activate flutterfire_cli` then `flutterfire configure`.
Not required on Android because `Firebase.initializeApp()` reads `google-services.json`.)

## 2. Authentication

Console -> Authentication -> Sign-in method -> enable **Google**.
After saving, open the Google provider again and copy the **Web client ID**
(or take the `client_type: 3` entry from `google-services.json`) into `.env`:

```
GOOGLE_WEB_CLIENT_ID=<web client id>.apps.googleusercontent.com
```

## 3. Cloud Storage (Cloudinary free plan)

Firebase Storage needs the paid Blaze plan, so report uploads go to Cloudinary
(approved by the lecturer). The old Firebase Storage implementation
(`FirebaseStorageService`, `storage.rules`) and the `firebase_storage` dependency were removed.

1. Create a free Cloudinary account and note the **Cloud name** (Settings -> API Keys).
2. Settings -> Upload -> Upload presets -> Add: **Signing mode = Unsigned**, e.g. `fap_reports_unsigned`.
3. Add to `.env` (git-ignored):
   ```
   CLOUDINARY_CLOUD_NAME=<cloud name>
   CLOUDINARY_UPLOAD_PRESET=<preset name>
   ```
4. Files are uploaded as raw assets to `reports/<firebase-uid>/<timestamp>_<file>.csv`.
   No API secret is stored in the app. The upload history shown in Profile is kept
   locally per user (Cloudinary listing needs the secret).

## 4. Cloud Messaging

Nothing to configure in code. On the device, accept the notification permission.
Get the token from **Profile** screen, then Console -> Messaging -> *Send test
message* -> paste the token.

## 5. Analytics DebugView

```powershell
adb shell setprop debug.firebase.analytics.app com.example.flutter_application_1
# when finished:
adb shell setprop debug.firebase.analytics.app .none.
```
Console -> Analytics -> DebugView.

## 6. Crashlytics

Console -> Crashlytics -> Enable. Crash reports appear after the app is
*reopened* following a crash. The Gradle plugin `com.google.firebase.crashlytics`
is already configured.

## 7. Remote Config

Console -> Remote Config -> add parameters (see `firebase/remoteconfig.template.md`):
`show_banner` (Boolean), `max_items` (Number), `portal_announcement` (String) -> **Publish changes**.
Tap the refresh icon on Home (it calls `fetchAndActivate`) to see the change.

## 8. Run and verify

```powershell
flutter pub get
flutter analyze lib
flutter test
flutter run -d <device-id>
```

Then follow `docs/firebase-evidence-checklist.md` to collect the screenshots.
