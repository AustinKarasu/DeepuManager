# Deepu Manager

Deepu Manager is a Flutter Android stock register application backed by a VPS API and VPS database. The server is authoritative for authentication, user approvals, audit logs, stock records, reports, and backups.

## Highlights

- Material 3 UI inspired by traditional stock register books
- VPS-backed password authentication
- Optional biometric and secure PIN unlock after enabling them from Profile Settings
- Admin approval, user management, user deletion, and audit logs
- Stock register CRUD, duplicate, search, filters, ledger-style history, dashboard, analytics, and reports
- XLSX and PDF export with professional stock register formatting
- In-app spreadsheet-style register view
- Server-side backup snapshot endpoint for administrators

## Build

Install Flutter stable, then run:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release `
  --dart-define=DEEPU_API_BASE_URL=<private-api-url> `
  --dart-define=DEEPU_ADMIN_EMAIL=<private-admin-email> `
  --dart-define=DEEPU_ADMIN_PASSWORD=<private-admin-password>
```

Admin bootstrap credentials and VPS details are supplied privately at build/deploy time. Do not commit them or include them in release notes.

## VPS Backend

The backend source lives in `server/`.

```bash
cp .env.example .env
npm install
npm run migrate
npm run seed
npm start
```

Required `.env` values:

- `PORT`
- `DATABASE_PATH`
- `JWT_SECRET`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`
