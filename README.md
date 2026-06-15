# DeepuLogger

DeepuLogger is an offline-first Flutter Android stock register app. The phone is the primary database and backend; a VPS sync backend can be enabled for admin review, user approvals, remote backups, and multi-device recovery.

## Highlights

- Material 3 UI inspired by traditional stock register books and the provided mobile mockups
- Encrypted local SQLite database
- Password, PIN, fingerprint, and face authentication support
- JWT-style local session tokens with expiry
- Device-specific users and admin approval workflow
- Stock register, ledger, history, analytics, reports, audit logs, and backups
- XLSX, PDF, and CSV export
- In-app spreadsheet-style editor for stock entries
- Optional Node.js VPS backend for sync and admin oversight

## First Build

Install Flutter stable, then run:

```powershell
flutter pub get
flutter run
```

If platform folders are missing because this repository was created without the Flutter CLI available, run:

```powershell
flutter create --platforms android .
flutter pub get
flutter run
```

Admin bootstrap credentials are supplied at build/deploy time through private environment values. They are intentionally not committed to the repository or written in release notes.

## VPS Backend

The backend source lives in `server/`. Copy it to the VPS, set `.env`, install Node 20+, then run:

```bash
cp .env.example .env
npm install
npm run migrate
npm run seed
npm start
```

The app remains fully usable offline. VPS sync is optional and queued locally when the network is unavailable.
