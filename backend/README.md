# CVNova Backend

FastAPI + PostgreSQL. Runs as a **single-user, local app** — there's no
login, no signup, no tokens. Every request is implicitly "the" local user.

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
API layer         (app/api)          — HTTP concerns: request/response, status codes
Service layer      (app/services)     — business logic
Repository layer   (app/repositories) — data access: the only place queries live
Model layer         (app/models)       — SQLAlchemy ORM tables
Schema layer         (app/schemas)      — Pydantic request/response contracts
```

Everything is async end-to-end (asyncpg + SQLAlchemy 2.0 async ORM), per the
project's async-programming rule.

## Single-user mode

There's no auth system. `app/api/deps.py`'s `get_current_user` dependency
auto-provisions one fixed-UUID `users` row (`00000000-0000-0000-0000-000000000001`,
`local@cvnova.app`) the first time the app is ever hit, and returns that
same row on every request after that. No request needs a header, a
cookie, or a token of any kind.

This is deliberate rather than just deleting `user_id` off `Resume`
entirely: keeping a real row means `resumes.user_id`'s foreign key,
`ResumeService`, and every existing query stay exactly as they were —
only *where* "the current user" comes from changed. If the app ever needs
multiple profiles again (e.g. a "switch profile" feature, still without
real authentication), the seam to extend is this same dependency.

`GET /api/v1/users/me` still exists and still works — it just always
returns this one local profile.

## API endpoints

| Method | Path                   | Description                          |
|--------|------------------------|---------------------------------------|
| GET    | `/api/v1/users/me`     | Returns the local profile             |
| GET    | `/api/v1/resumes`      | List resumes (summary shape)          |
| POST   | `/api/v1/resumes`      | Create a resume (title + template only; first one becomes primary) |
| GET    | `/api/v1/resumes/{id}` | Full resume document. 404 if it doesn't exist |
| PUT    | `/api/v1/resumes/{id}` | Full-document replace (autosave)      |
| DELETE | `/api/v1/resumes/{id}` | Delete; promotes another resume to primary if the deleted one was primary |
| POST   | `/api/v1/resumes/{id}/duplicate` | Deep-copy a resume, appended "(Copy)" |
| GET    | `/api/v1/ai/models`    | Auto-detected list of locally installed Ollama models |
| POST   | `/api/v1/ai/generate`  | Generate resume content (non-streaming), returns full text |
| POST   | `/api/v1/ai/generate/stream` | Same, but streams chunked text as it's generated |
| POST   | `/api/v1/ats/analyze`  | Upload a PDF resume (+ optional comma-separated target keywords), get scored |
| GET    | `/api/v1/ats/analyses` | List past analyses (summary shape) |
| GET    | `/api/v1/ats/analyses/latest` | Most recent analysis, 404 if none yet |
| GET    | `/api/v1/ats/analyses/{id}` | Full analysis (score + feedback) |
| GET    | `/health`              | Liveness check                        |

## Database schema

`users` — a single row in practice (see "Single-user mode" above).

| column           | type      | notes                        |
|------------------|-----------|-------------------------------|
| id               | UUID (PK) | fixed for the local user      |
| email            | varchar   | unique, indexed               |
| hashed_password  | varchar   | unused placeholder — nothing ever checks it |
| full_name        | varchar   |                                |
| role             | enum      | guest / user / admin — vestigial, nothing branches on it yet |
| is_active        | bool      | default true                  |
| is_verified      | bool      | default false                 |
| created_at / updated_at | timestamptz | server-side defaults    |

`resumes`

| column | type | notes |
|--------|------|-------|
| id | UUID (PK) | |
| user_id | UUID (FK → users.id, cascade delete) | always the local user's id |
| title, template, theme_color, font, is_primary | scalar columns | one resume is `is_primary` at a time, enforced in `ResumeService` |
| photo_url, headline, professional_summary, personal_info | scalar / JSON | |
| experience, projects, education, certifications, achievements, skills, languages, interests, references, links, custom_sections | **JSON** (JSONB on Postgres, plain JSON on SQLite) | repeatable sections |
| section_order, hidden_sections | JSON array | drag-drop order + show/hide state |
| created_at / updated_at | timestamptz | |

**Design decision — JSONB over full normalization:** the repeatable
sections (experience, education, projects, etc.) are stored as JSON arrays
on the `resumes` row rather than as ~10 separate normalized tables. A resume
is edited and autosaved as one document, reordered by the user, and read
back as a whole — there's no query pattern here that benefits from joining
across section tables. Every section's shape is still enforced — just at
the API boundary (`app/schemas/resume_sections.py`) rather than by foreign
keys.

The JSON column type is dialect-aware (`PortableJSON` in
`app/models/resume.py`): real `JSONB` on Postgres, plain `JSON` on SQLite.

Migrations: `alembic revision --autogenerate -m "..."` then
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
`leadership_description`, `custom_section`. One `/ai/generate` endpoint
is parameterized by `content_type` rather than 11 near-identical endpoints
— each type maps to its own prompt template in `prompts.py`.

**Tone** (`Tone` enum): `professional`, `technical`, `executive`,
`creative`, `minimal`, `student` — folded into the system prompt as
guidance text.

**Context is a free-form `dict[str, str]`** rather than a fixed schema per
content type. `prompts.py` only renders the keys relevant to the requested
content type into the prompt; irrelevant/missing keys are silently dropped.

**No fact invention**: the system prompt explicitly instructs the model to
work only from what's given and never invent employers, dates, or numbers.

**Streaming**: `/ai/generate/stream` awaits the *first* chunk before
constructing the `StreamingResponse`, so the common failure case (Ollama
not running at all) surfaces as a normal `503` instead of a `200` that
immediately dies mid-stream. A failure *after* the first chunk falls back
to an inline `[error]` message in the body.

## Testing strategy

`tests/` runs against real Postgres (`TEST_DATABASE_URL`, defaults to
`postgresql+asyncpg://cvnova:cvnova@localhost:5432/cvnova_test`) rather
than SQLite — this app uses Postgres-native column types (JSONB, native
UUID) in a few places that aren't portable to SQLite, so matching
production's dialect avoids false positives/negatives from dialect
differences. Each test gets a fresh schema (`create_all` before,
`drop_all` after) via the `db_session` fixture.

```bash
createdb -O cvnova cvnova_test   # once, if it doesn't exist yet
pytest -v
```

Resume coverage: creating a resume auto-marks it primary; list returns the
lightweight summary shape (no section content); get/update/delete/duplicate
all work against the local user's resumes; full-document update
round-trips nested sections correctly; unknown section keys in
`section_order` are rejected (422); marking a second resume primary unsets
the first; deleting the primary resume promotes another one; duplicate
deep-copies content and resets `is_primary`.

AI coverage: uses a `FakeOllamaClient` (in `tests/test_ai.py`) injected via
`app.dependency_overrides[get_ollama_client]` — no real Ollama instance
needed to run the suite. Covers: generate returns content and echoes back
model/content_type/tone; context values actually appear in the built
prompt; requesting a specific model overrides the default; an invalid
`content_type` is rejected (422, since it's a real enum); a failed Ollama
call surfaces as 503 (both for `/generate` and `/models`); the streaming
endpoint returns the fully-assembled text when consumed non-streaming by
the test client; streaming returns 503 on an *immediate* connection
failure; `/models` correctly parses Ollama's response shape into
`AIModelInfo`.

All 18 tests pass.

## ATS resume scoring

`POST /api/v1/ats/analyze` takes a PDF upload (+ optional comma-separated
target keywords) and returns a score. Deliberately **rule-based, not
LLM-based** (`app/ats/scorer.py`) — a score needs to be reproducible and
available even when Ollama isn't running, and this is close to how real ATS
keyword scanners actually work anyway: it checks resume length, standard
section headers, presence of contact info, action-verb usage in bullets,
quantified achievements, and keyword coverage against either the caller's
target list or a generic keyword bank if none is given. Results persist to
`resume_analyses` so `/ats/analyses/latest` can drive a dashboard card
without re-uploading anything.

`app/ats/pdf_extractor.py` isolates `pypdf` behind one function — encrypted
PDFs get a zero-length-password decrypt attempt, and a PDF with no
extractable text (e.g. a scanned image) surfaces as a clean 422 rather than
an empty score.

ATS coverage (`tests/test_ats.py`, using `reportlab`-generated PDFs so the
tests exercise real PDF parsing, not mocked text): a detailed, well-formed
resume scores meaningfully higher than a thin one; non-PDF uploads are
rejected (415); a malformed PDF is rejected (422); supplying target
keywords actually changes the keyword score and reports the right missing
keywords; list/latest/get-by-id all work; `/latest` 404s when nothing's
been analyzed yet.

All 25 tests pass (18 above + 7 ATS).

## What's stubbed / not yet built

- Resume version history / compare / restore (Resume Version Control phase)
- Portfolio/cover-letter/interview generation — reserved folders
  (`app/portfolio`, `app/interview`, `app/analytics`) exist but are empty
- ATS scoring is rule-based only for now — no LLM-generated qualitative
  feedback layered on top yet (would reuse the `OllamaClient`/`AIService`
  pattern, same as resume content generation)
- No caching of AI responses — regenerating the same content_type+context
  calls Ollama again every time
- No rate limiting on AI generation — worth adding once this is
  user-facing, since local LLM generation is slow enough that concurrent
  requests could tie up the Ollama instance

## Next phase

Layer LLM-generated qualitative feedback on top of the rule-based ATS
score (e.g. rewritten bullet suggestions, a tailored improvement plan) —
optional enhancement on an already-working deterministic score, not a
replacement for it.
