# Remote Config parameters (Firebase Console > Remote Config)

Defaults live in `FirebaseRemoteConfigService.defaults`; publish these keys in the
Console to override them without rebuilding the app.

| Key                  | Type    | Default | Visible effect                                                        |
|----------------------|---------|---------|-----------------------------------------------------------------------|
| `show_banner`        | Boolean | `true`  | Shows/hides the announcement banner on **Home**                       |
| `max_items`          | Number  | `10`    | Caps how many of today's sessions Home lists (note shows `n/total`)   |
| `portal_announcement`| String  | (text)  | Text inside the Home banner                                           |
| `enable_ai_assistant`| Boolean | `true`  | Enables the AI Assistant screen                                       |

Fetch interval: debug builds fetch every time; release builds cache for 5 minutes.
