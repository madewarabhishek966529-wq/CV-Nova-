# CVNova — Setup Notes

CVNova now runs as a **single-user, local app**. There is no login, no
signup, no accounts, no tokens — you open the app and you're straight into
your resumes. This section explains what changed and why; skip to
"Getting it running" if you just want to build it.

## Why no auth

This was a deliberate removal, not a bug fix. The app doesn't need
multi-tenant accounts to be useful — one person, one device (or one shared
local backend), one set of resumes.

**Backend (`backend/app/api/deps.py`):** the `get_current_user` dependency
no longer validates a Bearer token. Instead, it auto-provisions a single
fixed-UUID row in `users` (`00000000-0000-0000-0000-000000000001`,
`local@cvnova.app`) the first time the app is ever hit, and returns that
same row on every request after. Every other endpoint (`resumes.py`,
`ai.py`) needed **zero changes** — they still depend on `CurrentUser`,
which now just resolves differently.

Removed entirely: `endpoints/auth.py`, `services/auth_service.py`,
`schemas/auth.py`, `core/security.py` (JWT + password hashing), the
`passlib`/`bcrypt`/`python-jose`/`slowapi` dependencies, and the JWT
settings (`SECRET_KEY`, `ALGORITHM`, token expiry) from config.

**Flutter (`lib/`):** removed the login/signup screens, `auth_provider.dart`,
`auth_state.dart`, `auth_service.dart`, `token_storage.dart`. The router no
longer has `/login`/`/signup` routes — the splash screen goes straight to
the dashboard. `ApiClient` no longer attaches any `Authorization` header;
`ResumeService` and its two providers (`resume_list_provider.dart`,
`resume_editor_provider.dart`) no longer thread a token through every call.

I ran this end to end against a fresh database before calling it done:
listing resumes, creating one, and reading `/users/me` all work with zero
auth headers, from the very first request the backend ever receives.

Tests: rewrote `tests/conftest.py` / `test_resumes.py` / `test_ai.py`
(deleted `test_auth.py`, and dropped the multi-user ownership-isolation
tests, which no longer apply with one local user). Along the way I found
and fixed an unrelated pre-existing issue: the test suite ran against
in-memory SQLite, but `User`/`Resume` use Postgres-native `UUID` columns —
incompatible with SQLite, so those tests were silently broken before this
change too. Tests now run against real Postgres (`TEST_DATABASE_URL`),
matching production. All 18 tests pass.

## ATS resume scoring (new)

Added a real feature, not a stub: upload a PDF resume and get it scored.

**Backend:** `POST /api/v1/ats/analyze` (multipart PDF + optional
comma-separated target keywords) → rule-based scoring (`app/ats/scorer.py`)
across formatting, keyword coverage, and impact (action verbs + quantified
results), persisted so `/ats/analyses/latest` can drive a dashboard card.
Rule-based rather than LLM-based on purpose — it works even when Ollama
isn't running. Verified against real generated PDFs, not just unit tests
with mocked text — see `backend/README.md` for the full writeup and what's
covered by `tests/test_ats.py`.

**Flutter:** new `AtsAnalyzerScreen` (`lib/screens/ats/`) — pick a PDF
(`file_picker`), optionally paste target keywords, upload, see the score
broken down by dimension plus strengths/weaknesses/suggestions, with a
history list below. `lib/services/ats_service.dart` +
`lib/providers/ats_provider.dart` wire it up; `ApiClient` gained a
`postMultipart` method for the file upload.

**Dashboard "fix":** the dashboard previously showed two hardcoded fake
scores (`0.72`, `0.58`) and a fake "profile completion" ring (`0.4`) —
numbers that were never wired to anything real. Replaced with a single ATS
Score card driven by actual analysis data: shows the real score once one
exists, or an honest "upload a resume to see your score" empty state
CTA when it doesn't, rather than a number that was never true.

## Getting it running

### Backend

```bash
cd backend
cp .env.example .env
pip install -r requirements.txt
docker compose up -d          # starts Postgres + Redis
uvicorn app.main:app --reload
```

No env var setup beyond `DATABASE_URL`/`REDIS_URL` (already defaulted to
match `docker-compose.yml`) — there's no `SECRET_KEY` to generate anymore.

### Flutter

The zip contains `lib/` (Dart source) and now a `pubspec.yaml`, but still
no `android/`, `ios/`, or other platform folders — a Flutter app can't
build without them, and hand-authoring native Xcode/Gradle project files
here would risk a version mismatch with whatever Flutter/Xcode you have
installed. Generate them with the official tool instead:

```bash
# From the project root (where pubspec.yaml lives):
flutter create .
flutter pub get
flutter run
```

`flutter create .` is safe to run with `lib/` already in place — it only
adds the platform folders, it won't touch your existing source.

### Backend base URL

`lib/utils/constants.dart`:

```dart
static const apiBaseUrl = 'http://localhost:8000/api/v1';
```

- Android emulator: `localhost` won't reach your host machine — use
  `10.0.2.2` instead.
- iOS simulator / web / desktop: `localhost` works as-is.
- Physical device: use your host machine's LAN IP.

### One thing to check after `flutter create .`

`AndroidManifest.xml` needs internet permission to reach the backend
(included by default in modern `flutter create` templates, but worth
confirming):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```
