# CVNova — Setup & Fix Notes

## The bug that was fixed: "doesn't login after signup"

**Root cause:** email case-sensitivity.

- Signup stored the email exactly as typed (e.g. `CaseUser2@example.com`).
- Login compared emails with an exact, case-sensitive match.
- So signing up as `CaseUser2@example.com` and logging in as
  `caseuser2@example.com` — same password, different casing — failed with
  `401 Incorrect email or password`, even though the credentials were
  correct. This is extremely common in practice: phone keyboards
  auto-capitalize, people retype emails inconsistently, etc.
- It also allowed **duplicate accounts** for the same address in different
  casing, since the uniqueness check was case-sensitive too.

Reproduced directly against the backend (not guessed from reading code):

```
POST /auth/signup {"email": "CaseUser2@example.com", ...}   -> 201 Created
POST /auth/login  {"email": "caseuser2@example.com", ...}   -> 401 Incorrect email or password  (BEFORE FIX)
POST /auth/login  {"email": "caseuser2@example.com", ...}   -> 200 OK, tokens returned            (AFTER FIX)
```

**Fix — normalize email in one place, at the schema boundary:**
- `backend/app/schemas/user.py` — `UserCreate.email` now strips + lowercases
  via a `field_validator`.
- `backend/app/schemas/auth.py` — `LoginRequest.email` does the same, so it
  always agrees with what was stored at signup.
- `lib/screens/auth/signup_screen.dart` and `login_screen.dart` — lowercase
  the email client-side too (defense in depth), and set
  `textCapitalization: TextCapitalization.none` on the email fields so
  mobile keyboards don't auto-capitalize as you type.

Everything else in the auth chain (JWT issuing/verification, secure token
storage, the Riverpod auth provider, routing, rate limiting) was tested
directly against a live instance of the backend and worked correctly — that
wasn't where the problem was.

## Project structure issues that were cleaned up

The uploaded zip had two accidental artifacts, likely from a bad
zip/re-zip step on export:
- `backend/backend/` — a full nested duplicate of the entire backend,
  including a baked-in Python virtualenv (`.venv`). This alone accounted
  for ~115MB of the 75MB zip's uncompressed size.
- `backend/lib/` — a stray duplicate of the Flutter `lib/` source tree.

Both were removed. Nothing referenced them.

## Why this zip couldn't run as-is, and what to do

The zip only contained `lib/` (Dart source) and `backend/` (the FastAPI
service) — there was **no `pubspec.yaml`, and no `android/`, `ios/`, `web/`,
`linux/`, `macos/`, or `windows/` platform folders**. A Flutter app cannot
build without these; `lib/` alone is not a project.

I added `pubspec.yaml` (with the exact packages the code actually imports —
`flutter_riverpod`, `go_router`, `http`, `flutter_secure_storage`,
`shared_preferences`, `google_fonts`, `flutter_animate`) and
`analysis_options.yaml`.

I intentionally did **not** hand-write the `android/` and `ios/` native
project files. Those are generated from templates tied to your exact
installed Flutter/Xcode/Gradle version — hand-authoring them risks
introducing a *new*, harder-to-diagnose build error from a version mismatch.
The correct and safe way to generate them is a single official command:

```bash
# From the project root (where pubspec.yaml now lives):
flutter create .
```

This scaffolds `android/`, `ios/`, and any other platforms you have enabled,
without touching your existing `lib/` — safe to run even with `lib/`
already in place. Then:

```bash
flutter pub get
flutter run
```

### One thing to double check after `flutter create .`

`AndroidManifest.xml` needs internet permission for the app to reach the
backend (this is included by default in modern `flutter create` templates,
but worth confirming):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Backend base URL (already noted in `lib/utils/constants.dart`)

```dart
static const apiBaseUrl = 'http://localhost:8000/api/v1';
```

- Android emulator: `localhost` won't reach your host machine — use
  `10.0.2.2` instead.
- iOS simulator / web / desktop: `localhost` works as-is.
- Physical device: use your host machine's LAN IP.

## Running the backend

```bash
cd backend
cp .env.example .env        # fill in a real SECRET_KEY for anything beyond local dev
pip install -r requirements.txt
# Postgres + Redis must be reachable at the URLs in .env — docker-compose.yml
# starts both if you don't already have them running:
docker compose up -d
uvicorn app.main:app --reload
```

I verified this exact sequence (Postgres via docker-compose equivalents,
`pip install -r requirements.txt`, `uvicorn app.main:app`) boots cleanly and
handles signup → login correctly end to end.
