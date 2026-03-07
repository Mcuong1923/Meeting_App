# Seed & Migration: Teams + User Backfill + Full Auth Seed

## Prerequisites

1. **Node.js** installed (v18+)
2. **Firebase Service Account Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk)
   - Click **Generate New Private Key**
   - Save exactly as `seed/serviceAccountKey.json` (This file is in `.gitignore` and won't be pushed).
3. Install dependencies:
   ```bash
   cd seed
   npm install firebase-admin dotenv
   ```

## 1. Seed Full Auth (User Thật)

This script creates real Firebase Auth users and corresponding Firestore user profiles for testing. It will seed 3 teams per department (aside from the general team) with 5 users each.

### Configurations
- **Seed Password**: `Test@123456` (Used for all generated test accounts).
- Users are created with the email format: `user_{deptIndex}_{teamIndex}_{i}@company.com` (e.g. `user_01_01_01@company.com`).
- *(Optional)* Create a `.env` file in the `seed/` directory to override the password:
  ```env
  SEED_PASSWORD=YourOwnPassword@123
  ```

### Run
```bash
node seed_full_auth.js
```

### Safety & Idempotent Design
- **Idempotent**: Safe to run multiple times. If an auth user exists, it reuses the UID.
- **No Overwrite**: For users where `role != "employee"`, it completely skips overwriting `role`, `status`, `accountType`, and `isRoleApproved`. It will only backfill missing team fields if null.

---

## 2. Seed & Migrate (Legacy Backfill)

If you only want to backfill missing users into default `__general` teams (without creating new Auth records), use `seed_and_migrate.js`.

### Run
```bash
node seed_and_migrate.js
```

### What it does (seed_and_migrate.js)
- **Step A: Seed Teams** - Reads `teams_seed.json` to create/update necessary teams.
- **Step B: Backfill Users** - Queries users missing `teamId` and assigns them to `${departmentId}__general`.
- **NEVER touches**: `role`, `status`, `isRoleApproved`, `accountType`. Only updates team references.

---

## File Structure

```
seed/
├── README.md               ← This instruction file
├── teams_seed.json         ← Seed data containing Departments & Teams mapping
├── seed_and_migrate.js     ← Legacy migration script (only backfills existing users)
├── seed_full_auth.js       ← Full seed script (creates Auth and Firestore test users)
├── .env                    ← (Optional) Override secrets
└── serviceAccountKey.json  ← YOUR service account key (DO NOT COMMIT)
```
