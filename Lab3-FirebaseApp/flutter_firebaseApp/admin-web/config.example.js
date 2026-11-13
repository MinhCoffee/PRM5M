// Copy to config.js (git-ignored) and fill in. Never commit config.js.
export default {
  // Firebase Console -> Project settings -> Your apps -> Web app -> SDK config.
  firebase: {
    apiKey: "...",
    authDomain: "fap-attendance-85250.firebaseapp.com",
    projectId: "fap-attendance-85250",
    appId: "...",
  },
  // Same value as GOOGLE_SPREADSHEET_ID in the app's .env.
  spreadsheetId: "...",
  // Google accounts allowed to open the dashboard (also need Viewer access to the sheet).
  adminEmails: ["admin@example.com"],
};
