# CVNova Backend — Phase 2: Auth Foundation

FastAPI + PostgreSQL + JWT authentication. This phase gives the Flutter
`login_screen.dart` / `signup_screen.dart` a real backend to call.

## Run it

```bash
# 1. Start local Postgres + Redis
docker compose up -d

# 2. Install deps
python -m venv .venv 
source .venv/bin/activate
pip install -r requirements-dev.txt

# 3. Configure
cp .env.example .env   # defaults already match docker-compose.yml

# 4. Run (DEBUG=true auto-creates tables; use Alembic once you branch off dev)
uvicorn app.main:app --reload
```

Docs at `http://localhost:8000/docs` (only available when `DEBUG=true`).

## Architecture

Layered, so business logic never touches SQLAlchemy directly and endpoints
never touch the database directly:

```
API layer        (app/api)          — HTTP concerns: request/response, status codes, auth deps
Service layer     (app/services)     — business logic: signup/login/refresh rules
Repository layer  (app/repositories) — data access: the only place queries live
Model layer        (app/models)       — SQLAlchemy ORM tables
Schema layer        (app/schemas)      — Pydantic request/response contracts
```

Request flow for login: `endpoints/auth.py` → `AuthService.login()` →
`UserRepository.get_by_email()` → `core/security.verify_password()` →
`core/security.create_access_token()` / `create_refresh_token()`.

Everything is async end-to-end (asyncpg + SQLAlchemy 2.0 async ORM), per the
project's async-programming rule.

## API endpoints

| Method | Path                   | Auth      | Description                          |
|--------|------------------------|-----------|---------------------------------------|
| POST   | `/api/v1/auth/signup`  | none      | Create account, returns the user      |
| POST   | `/api/v1/auth/login`   | none      | Rate-limited 10/min. Returns access + refresh tokens |
| POST   | `/api/v1/auth/refresh` | none      | Exchange a refresh token for a new access token |
| GET    | `/api/v1/users/me`     | Bearer    | Returns the authenticated user        |
| GET    | `/api/v1/resumes`      | Bearer    | List the user's resumes (summary shape) |
| POST   | `/api/v1/resumes`      | Bearer    | Create a resume (title + template only; first one becomes primary) |
| GET    | `/api/v1/resumes/{id}` | Bearer    | Full resume document. 404 if not owned by caller |
| PUT    | `/api/v1/resumes/{id}` | Bearer    | Full-document replace (autosave)      |
| DELETE | `/api/v1/resumes/{id}` | Bearer    | Delete; promotes another resume to primary if the deleted one was primary |
| POST   | `/api/v1/resumes/{id}/duplicate` | Bearer | Deep-copy a resume, appended "(Copy)" |
| GET    | `/api/v1/ai/models`    | Bearer    | Auto-detected list of locally installed Ollama models |
| POST   | `/api/v1/ai/generate`  | Bearer    | Generate resume content (non-streaming), returns full text |
| POST   | `/api/v1/ai/generate/stream` | Bearer | Same, but streams chunked text as it's generated |
| GET    | `/health`              | none      | Liveness check                        |

Auth uses two token types (`type: "access"` / `"refresh"` claim inside the
JWT) so a refresh token can never be used where an access token is expected,
and vice versa — enforced in `core/security.decode_token()`.

## Database schema (Phase 2)

`users`
| column           | type      | notes                        |
|------------------|-----------|-------------------------------|
| id               | UUID (PK) | server-generated              |
| email            | varchar   | unique, indexed               |
| hashed_password  | varchar   | bcrypt, never returned by API |
| full_name        | varchar   |                                |
| role             | enum      | guest / user / admin          |
| is_active        | bool      | default true                  |
| is_verified      | bool      | default false — email verification is a TODO for a later phase |
| created_at / updated_at | timestamptz | server-side defaults    |

`resumes`

| column | type | notes |
|--------|------|-------|
| id | UUID (PK) | |
| user_id | UUID (FK → users.id, cascade delete) | indexed |
| title, template, theme_color, font, is_primary | scalar columns | one resume per user is `is_primary` at a time, enforced in `ResumeService` |
| photo_url, headline, professional_summary, personal_info | scalar / JSON | |
| experience, projects, education, certifications, achievements, skills, languages, interests, references, links, custom_sections | **JSON** (JSONB on Postgres, plain JSON on SQLite) | repeatable sections |
| section_order, hidden_sections | JSON array | drag-drop order + show/hide state |
| created_at / updated_at | timestamptz | |

**Design decision — JSONB over full normalization:** the repeatable
sections (experience, education, projects, etc.) are stored as JSON arrays
on the `resumes` row rather than as ~10 separate normalized tables. A resume
is edited and autosaved as one document, reordered by the user, and read
back as a whole — there's no query pattern here that benefits from joining
across section tables, and full normalization would mean 10+ extra tables,
repositories, and cascade rules for no real gain at this stage. Every
section's shape is still enforced — just at the API boundary
(`app/schemas/resume_sections.py`) rather than by foreign keys. If a future
phase needs to query *across* resumes by section content (e.g. "find all
resumes mentioning React" for analytics), that's the point to introduce a
normalized or indexed side-table — not before.

The JSON column type is dialect-aware (`PortableJSON` in
`app/models/resume.py`): real `JSONB` on Postgres, plain `JSON` on SQLite,
so the model works in both production and the in-memory test DB without
two separate model definitions.

Migrations: `alembic revision --autogenerate -m "create users table"` then
`alembic upgrade head`. `DEBUG=true` auto-creates tables via
`metadata.create_all` for fast local iteration — never used in production,
where Alembic is the only source of schema truth.

## AI generation (Ollama)

**Requires Ollama running separately** — this backend calls out to it over
HTTP, it doesn't bundle or manage it. `ollama serve`, then
`ollama pull llama3` (or any model) before `/api/v1/ai/*` will work.
`OLLAMA_BASE_URL` defaults to `http://localhost:11434`.

**Architecture**: `app/ai/enums.py` (`ContentType`, `Tone`) →
`app/ai/prompts.py` (`build_prompt` — pure function, no I/O, takes a
content type + tone + free-form context dict and returns a system/user
prompt pair) → `app/ai/ollama_client.py` (`OllamaClient` — the only thing
that actually talks HTTP to Ollama) → `app/services/ai_service.py`
(`AIService` — orchestrates the two) → `app/api/v1/endpoints/ai.py`.

`OllamaClient` is injected via a FastAPI dependency (`get_ollama_client`),
the same pattern as `get_db` — tests override it with an in-memory fake,
so the test suite never makes a real network call to a local Ollama
instance and doesn't require Ollama to be running.

**Content types** (`ContentType` enum) cover every AI-writing item in the
spec: `summary`, `career_objective`, `experience_bullets`,
`responsibilities`, `project_description`, `achievement`,
`technical_skills`, `soft_skills`, `internship_description`,
`leadership_description`, `custom_section`. Rather than one endpoint per
content type (11 near-identical endpoints), there's one `/ai/generate`
endpoint parameterized by `content_type` — each type maps to its own
prompt template in `prompts.py`, so behavior is still fully distinct per
type, just without duplicating the endpoint/service/schema plumbing 11
times.

**Tone** (`Tone` enum): `professional`, `technical`, `executive`,
`creative`, `minimal`, `student` — folded into the system prompt as
guidance text, not the user prompt, so it shapes *how* something is
written without competing with the actual content instructions.

**Context is a free-form `dict[str, str]`** rather than a fixed schema per
content type — different content types care about different fields
(role/company for experience, project_name/tech_stack for projects), and a
free-form dict avoids 11 near-duplicate request schemas. `prompts.py` only
renders the keys relevant to the requested content type into the prompt;
irrelevant/missing keys are silently dropped rather than sent as blank
lines (small local models tend to produce boilerplate commentary about
blank fields otherwise).

**No fact invention**: the system prompt explicitly instructs the model to
work only from what's given and never invent employers, dates, or numbers
— important since this writes content for a legal-ish document (a resume)
where a plausible-sounding fabricated detail is a real risk with local
LLMs.

**Streaming**: `/ai/generate/stream` awaits the *first* chunk before
constructing the `StreamingResponse`, specifically so the common failure
case (Ollama not running at all) surfaces as a normal `503` instead of a
`200` that immediately dies mid-stream — HTTP can't change status code
after a response has started, so this is the only point a clean error
status is achievable. A failure *after* the first chunk (rarer) falls back
to an inline `[error]` message in the body, since headers are already sent
by then.

## Testing strategy

`tests/` uses an in-memory SQLite DB (`aiosqlite`) via a `get_db` override,
so tests don't need Postgres running. A `_reset_rate_limiter` autouse
fixture resets the shared slowapi limiter before each test — without it,
tests earlier in the run exhaust the login rate limit for later ones, since
the limiter is a module-level singleton keyed by client IP and every test
client shares the same IP.

Auth coverage: successful signup, duplicate email rejection (409),
password-too-short validation (422), successful login, wrong-password
rejection (401), `/me` requiring auth (401 without a token), `/me`
returning the right user, refresh-token flow issuing a new access token,
and refresh rejecting an access token used in its place.

Resume coverage: creating a resume auto-marks it primary; list returns the
lightweight summary shape (no section content); get/update/delete/duplicate
all enforce ownership (404, not 403, for another user's resume — doesn't
leak whether the id exists); full-document update round-trips nested
sections correctly; unknown section keys in `section_order` are rejected
(422); marking a second resume primary unsets the first; deleting the
primary resume promotes another one; duplicate deep-copies content and
resets `is_primary`.

AI coverage: uses a `FakeOllamaClient` (in `tests/test_ai.py`) injected via
`app.dependency_overrides[get_ollama_client]` — no real Ollama instance
needed to run the suite. Covers: generate returns content and echoes back
model/content_type/tone; context values actually appear in the built
prompt; requesting a specific model overrides the default; an invalid
`content_type` is rejected (422, since it's a real enum); a failed Ollama
call surfaces as 503 (both for `/generate` and `/models`); `/generate`
requires auth; the streaming endpoint returns the fully-assembled text
when consumed non-streaming by the test client; streaming returns 503 on
an *immediate* connection failure (validates the prime-the-first-chunk
behavior described above); `/models` correctly parses Ollama's response
shape into `AIModelInfo`.

```bash
pytest -v
```

All 29 tests pass as of this phase.

**Known dependency pin:** `bcrypt` is pinned to `4.0.1` — `passlib==1.7.4`'s
backend-detection code breaks against `bcrypt>=4.1` (a known upstream
incompatibility, not a CVNova bug). Keep this pin until passlib ships a fix.

## What's stubbed / not yet built

- Email verification (`is_verified` field exists, no send/verify flow yet)
- Forgot-password flow
- Google login
- Admin-only endpoints (role check exists via `CurrentAdmin` dependency, no routes use it yet)
- Rate limiting only covers `/login`; extend to other write endpoints as they're added
- Resume version history / compare / restore (Resume Version Control phase)
- ATS scoring, portfolio/cover-letter/interview generation — reserved
  folders (`app/ats`, `app/portfolio`, `app/interview`, `app/analytics`)
  exist but are empty
- AI generation has no rate limiting yet (unlike `/auth/login`) — worth
  adding once this is user-facing, since local LLM generation is slow
  enough that concurrent abuse could tie up the Ollama instance for
  everyone
- No caching of AI responses — regenerating the same content_type+context
  calls Ollama again every time

## Next phase

ATS scoring: analyze a resume and return overall/formatting/keyword/
experience/education/projects/grammar scores, weak/strong sections,
missing keywords, and an improvement plan — likely also Ollama-backed,
reusing the `OllamaClient`/`AIService` pattern from this phase.
