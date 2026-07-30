# CV Nova — Local Development Setup Guide

> **AI-powered resume builder** — Flutter frontend + FastAPI backend + PostgreSQL + Redis

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project Structure](#2-project-structure)
3. [Backend Setup](#3-backend-setup)
   - [3.1 Start Docker Services](#31-start-docker-services-postgresql--redis)
   - [3.2 Create Python Virtual Environment](#32-create-python-virtual-environment)
   - [3.3 Install Dependencies](#33-install-dependencies)
   - [3.4 Configure Environment Variables](#34-configure-environment-variables)
   - [3.5 Run Database Migrations](#35-run-database-migrations)
   - [3.6 Start FastAPI Server](#36-start-fastapi-server)
   - [3.7 Verify the Backend](#37-verify-the-backend)
4. [Flutter Setup](#4-flutter-setup)
5. [Windows-Specific: Docker Port Conflict Fix](#5-windows-specific-docker-desktop-port-conflict-fix)
6. [API Reference](#6-api-reference)
7. [Environment Variables](#7-environment-variables)
8. [Common Errors & Fixes](#8-common-errors--fixes)
9. [Stopping Everything](#9-stopping-everything)

---

## 1. Prerequisites

Make sure you have all of the following installed before proceeding:

| Tool | Minimum Version | Download |
|------|----------------|---------|
| **Docker Desktop** | 4.x | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **Python** | 3.11+ | [python.org](https://www.python.org/downloads/) |
| **Flutter SDK** | 3.22+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| **Git** | any | [git-scm.com](https://git-scm.com/) |

> **Optional:** [Ollama](https://ollama.com/) for local AI features (`ollama serve` + `ollama pull llama3`).  
> The app works fully without it — AI endpoints return 503 when Ollama is unavailable.

---

## 2. Project Structure

```
cv_nova/
├── backend/                  ← FastAPI backend (Python)
│   ├── app/
│   │   ├── api/              ← Route handlers
│   │   ├── core/             ← Config, security, logging
│   │   ├── database/         ← SQLAlchemy engine & session
│   │   ├── models/           ← ORM models (User, Resume)
│   │   ├── repositories/     ← Data-access layer
│   │   ├── schemas/          ← Pydantic request/response models
│   │   ├── services/         ← Business logic
│   │   ├── ai/               ← Ollama client & prompts
│   │   └── main.py           ← FastAPI app entry point
│   ├── alembic/              ← Database migrations
│   ├── .env                  ← Local environment variables (git-ignored)
│   ├── .env.example          ← Template for .env
│   ├── docker-compose.yml    ← PostgreSQL + Redis containers
│   └── requirements.txt      ← Python dependencies
│
└── lib/                      ← Flutter frontend (Dart)
    ├── main.dart
    ├── models/               ← Dart data models
    ├── providers/            ← Riverpod state management
    ├── routes/               ← GoRouter navigation
    ├── screens/              ← UI screens
    ├── services/             ← API client & auth service
    ├── theme/                ← App theme & typography
    └── utils/                ← Constants (API base URL, etc.)
```

---

## 3. Backend Setup

All commands below are run from the **`backend/`** directory unless noted otherwise.

```powershell
cd "d:\CODING\Git Project\Flutter Projects git\cv_nova\cv_nova\backend"
```

### 3.1 Start Docker Services (PostgreSQL + Redis)

```powershell
docker compose up -d
```

Wait ~10 seconds, then verify both containers are **healthy**:

```powershell
docker compose ps
```

Expected output:
```
NAME                 IMAGE                STATUS
backend-postgres-1   postgres:16-alpine   Up (healthy)
backend-redis-1      redis:7-alpine       Up (healthy)
```

> **Credentials (local dev only):**  
> PostgreSQL: `host=localhost port=5432 db=cvnova user=cvnova password=cvnova`  
> Redis: `redis://localhost:6379/0`

---

### 3.2 Create Python Virtual Environment

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**macOS / Linux (bash):**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

You should see `(.venv)` in your prompt after activation.

---

### 3.3 Install Dependencies

```powershell
pip install -r requirements.txt
```

Key packages installed:

| Package | Version | Purpose |
|---------|---------|---------|
| `fastapi` | 0.111.0 | Web framework |
| `uvicorn[standard]` | 0.30.1 | ASGI server |
| `sqlalchemy` | 2.0.31 | Async ORM |
| `asyncpg` | 0.29.0 | PostgreSQL async driver |
| `alembic` | 1.13.2 | Database migrations |
| `pydantic` | 2.8.2 | Data validation |
| `passlib[bcrypt]` | 1.7.4 | Password hashing |
| `bcrypt` | **3.2.2** | Bcrypt backend ⚠️ must be this version |
| `python-jose[cryptography]` | 3.3.0 | JWT tokens |
| `redis` | 5.0.7 | Redis client |
| `slowapi` | 0.1.9 | Rate limiting |

> ⚠️ **Important:** `bcrypt` must be pinned to `3.2.2`. Version 4.x removes `__about__.__version__` which `passlib 1.7.4` requires — using 4.x will cause HTTP 500 on every login/signup.

---

### 3.4 Configure Environment Variables

The `.env` file is already present at `backend/.env` with working local dev defaults. Review it and change `SECRET_KEY` before deploying anywhere:

```env
PROJECT_NAME=CVNova
DEBUG=true
API_V1_PREFIX=/api/v1

# PostgreSQL
DATABASE_URL=postgresql+asyncpg://cvnova:cvnova@localhost:5432/cvnova

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT — CHANGE THIS in production!
SECRET_KEY=581e4327934887a73c5bc3ea16ab16a27b8cf7752c93a6969a667d0cf51e3ed7
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# CORS
CORS_ORIGINS=*

# Ollama (optional — AI features)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_DEFAULT_MODEL=llama3
OLLAMA_REQUEST_TIMEOUT_SECONDS=60
```

> To generate a new secret key:
> ```python
> python -c "import secrets; print(secrets.token_hex(32))"
> ```

---

### 3.5 Run Database Migrations

Apply the Alembic migrations to create the `users` and `resumes` tables:

```powershell
alembic upgrade head
```

Expected output:
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> 0001, Initial schema — users and resumes tables.
```

> ℹ️ **Note:** In `DEBUG=true` mode, FastAPI also runs `create_all` on startup as a convenience. The migration is idempotent — it skips tables/types that already exist, so both paths are safe to use together.

Verify the tables were created:
```powershell
docker compose exec postgres psql -U cvnova -d cvnova -c "\dt"
```

Expected:
```
           List of relations
 Schema |      Name       | Type
--------+-----------------+-------
 public | alembic_version | table
 public | resumes         | table
 public | users           | table
```

---

### 3.6 Start FastAPI Server

> ⚠️ **Windows + Docker Desktop users — read section 5 first** if you get 404 errors on `localhost:8000`.

```powershell
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

The `--reload` flag enables hot reload during development.

Successful startup output:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [...] using WatchFiles
INFO:     Application startup complete.
INFO | app.main | CVNova starting up
```

---

### 3.7 Verify the Backend

**Health check:**
```powershell
curl http://127.0.0.1:8000/health
# → {"status":"ok","service":"CVNova"}
```

**Interactive API docs (DEBUG mode only):**
- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc

**Test signup:**
```powershell
curl -X POST http://127.0.0.1:8000/api/v1/auth/signup `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","password":"Password123","full_name":"Test User"}'
# → {"id":"...","email":"test@example.com","full_name":"Test User","role":"user","is_active":true,"is_verified":false,...}
```

**Test login:**
```powershell
curl -X POST http://127.0.0.1:8000/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{"email":"test@example.com","password":"Password123"}'
# → {"access_token":"eyJ...","refresh_token":"eyJ...","token_type":"bearer"}
```

**Test /users/me:**
```powershell
curl http://127.0.0.1:8000/api/v1/users/me `
  -H "Authorization: Bearer <access_token>"
# → {"id":"...","email":"test@example.com",...}
```

---

## 4. Flutter Setup

```powershell
# From the project root (cv_nova/)
flutter pub get
flutter run
```

The Flutter app points to `http://localhost:8000/api/v1` (defined in `lib/utils/constants.dart`).

**Platform notes:**

| Platform | `localhost` URL | Notes |
|----------|----------------|-------|
| Windows desktop | `http://localhost:8000` | ✅ Works directly |
| iOS Simulator | `http://localhost:8000` | ✅ Works directly |
| Web (Chrome) | `http://localhost:8000` | ✅ Works directly |
| Android Emulator | `http://10.0.2.2:8000` | ⚠️ `localhost` doesn't reach the host in the emulator |
| Physical device | `http://<your-LAN-IP>:8000` | ⚠️ Use `ipconfig` to find your IP |

> For Android Emulator or physical device, change `apiBaseUrl` in `lib/utils/constants.dart` accordingly.

---

## 5. Windows-Specific: Docker Desktop Port Conflict Fix

**Problem:** Docker Desktop's internal backend process (`com.docker.backend.exe`) binds to `0.0.0.0:8000` and its WSL relay (`wslrelay.exe`) binds to `[::1]:8000`. Since Windows resolves `localhost` to `::1` (IPv6) by default, all requests to `localhost:8000` get routed to Docker's relay instead of FastAPI.

**Fix (already applied):** The entry `127.0.0.1 localhost` has been added to `C:\Windows\System32\drivers\etc\hosts`. This forces `localhost` to resolve to `127.0.0.1` (IPv4) where uvicorn is listening.

**Verify the fix is in place:**
```powershell
findstr "CVNova" C:\Windows\System32\drivers\etc\hosts
# → 127.0.0.1       localhost    # CVNova dev fix
```

**If the fix isn't there or was removed, re-apply it:**

1. Open Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Add this line at the bottom:
   ```
   127.0.0.1       localhost    # CVNova dev fix
   ```
4. Save the file
5. Run `ipconfig /flushdns` in PowerShell

**Always start uvicorn with `--host 127.0.0.1`** (not `0.0.0.0`) to bind to the IPv4 loopback:
```powershell
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

---

## 6. API Reference

Base URL: `http://localhost:8000/api/v1`

### Authentication

| Method | Endpoint | Auth | Description |
|--------|---------|------|-------------|
| `POST` | `/auth/signup` | ❌ | Register a new user |
| `POST` | `/auth/login` | ❌ | Login — returns access + refresh tokens |
| `POST` | `/auth/refresh` | ❌ | Exchange refresh token for new tokens |

**Signup request body:**
```json
{ "email": "user@example.com", "password": "Password123", "full_name": "John Doe" }
```

**Login / Refresh request body:**
```json
// Login:
{ "email": "user@example.com", "password": "Password123" }
// Refresh:
{ "refresh_token": "eyJ..." }
```

**Token response:**
```json
{ "access_token": "eyJ...", "refresh_token": "eyJ...", "token_type": "bearer" }
```

---

### Users

| Method | Endpoint | Auth | Description |
|--------|---------|------|-------------|
| `GET` | `/users/me` | ✅ Bearer | Get current user profile |

---

### Resumes

All resume endpoints require `Authorization: Bearer <access_token>`.

| Method | Endpoint | Description |
|--------|---------|-------------|
| `GET` | `/resumes` | List all resumes for current user |
| `POST` | `/resumes` | Create a new resume |
| `GET` | `/resumes/{id}` | Get full resume by ID |
| `PUT` | `/resumes/{id}` | Full-document update (autosave) |
| `DELETE` | `/resumes/{id}` | Delete resume |
| `POST` | `/resumes/{id}/duplicate` | Duplicate a resume |

**Create resume body:**
```json
{ "title": "My Resume", "template": "modern" }
```

---

### AI (Requires Ollama running locally)

| Method | Endpoint | Auth | Description |
|--------|---------|------|-------------|
| `GET` | `/ai/models` | ✅ Bearer | List available Ollama models |
| `POST` | `/ai/generate` | ✅ Bearer | Generate content (non-streaming) |
| `POST` | `/ai/generate/stream` | ✅ Bearer | Generate content (streaming) |

> Returns `503 Service Unavailable` if Ollama is not running.

---

## 7. Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROJECT_NAME` | `CVNova` | App name shown in API docs |
| `DEBUG` | `false` | Enables SQL logging, Swagger UI, create_all |
| `API_V1_PREFIX` | `/api/v1` | URL prefix for all API routes |
| `DATABASE_URL` | `postgresql+asyncpg://...` | Async PostgreSQL connection string |
| `REDIS_URL` | `redis://localhost:6379/0` | Redis connection URL |
| `SECRET_KEY` | — | JWT signing key — **MUST change in production** |
| `ALGORITHM` | `HS256` | JWT algorithm |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access token lifetime |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Refresh token lifetime |
| `CORS_ORIGINS` | `*` | Comma-separated allowed origins (`*` = all) |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama API base URL |
| `OLLAMA_DEFAULT_MODEL` | `llama3` | Default model for AI features |
| `OLLAMA_REQUEST_TIMEOUT_SECONDS` | `60` | AI request timeout |

---

## 8. Common Errors & Fixes

### ❌ `AttributeError: module 'bcrypt' has no attribute '__about__'`
**Cause:** `bcrypt >= 4.0` is incompatible with `passlib 1.7.4`.  
**Fix:** `pip install bcrypt==3.2.2`

---

### ❌ `sqlalchemy.exc.ProgrammingError: type "user_role" already exists`
**Cause:** Running `alembic upgrade head` after the app already ran `create_all` in DEBUG mode.  
**Fix:** The migration is idempotent — this error should not occur with the current `0001_initial_schema.py`. If it does, run:
```powershell
alembic stamp head   # Mark DB as already at latest revision
```

---

### ❌ FastAPI returns `{"error":{"code":"http_error","message":"Not Found"}}` on `localhost:8000`
**Cause:** Docker Desktop's WSL relay intercepts `localhost:8000` before uvicorn.  
**Fix:** See [Section 5](#5-windows-specific-docker-desktop-port-conflict-fix). Always use `--host 127.0.0.1`.

---

### ❌ `Connection refused` on port 5432 or 6379
**Cause:** Docker containers not running.  
**Fix:**
```powershell
docker compose up -d
docker compose ps   # Check both show (healthy)
```

---

### ❌ Flutter `SocketException: Connection refused`
**Cause:** FastAPI server not running, or wrong IP for the platform.  
**Fix:**  
- Start the server: `uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload`  
- Android emulator: change `apiBaseUrl` to `http://10.0.2.2:8000/api/v1`

---

### ❌ HTTP 422 on `/auth/login`
**Cause:** Request body missing required fields or wrong format.  
**Fix:** Login expects JSON `{"email": "...", "password": "..."}` — not form-encoded.

---

### ❌ HTTP 401 on `/api/v1/users/me`
**Cause:** Missing or expired `Authorization: Bearer <token>` header.  
**Fix:** Call `/auth/login` first to get a fresh access token, then include it as:
```
Authorization: Bearer eyJ...
```

---

### ❌ Alembic `FATAL: database "cvnova" does not exist`
**Cause:** PostgreSQL container not initialized yet.  
**Fix:** Wait for Docker container to be healthy, then re-run:
```powershell
docker compose up -d
docker compose ps    # wait for (healthy)
alembic upgrade head
```

---

## 9. Stopping Everything

**Stop uvicorn:** Press `Ctrl+C` in the terminal running uvicorn.

**Stop Docker containers:**
```powershell
# Stop but keep data
docker compose stop

# Stop and remove containers (keeps volume data)
docker compose down

# Stop and remove EVERYTHING including database data
docker compose down -v
```

---

## Quick Reference — Full Start Sequence

```powershell
# 1. Navigate to backend
cd "d:\CODING\Git Project\Flutter Projects git\cv_nova\cv_nova\backend"

# 2. Start database + Redis
docker compose up -d

# 3. Activate virtual environment
.venv\Scripts\Activate.ps1

# 4. Install / verify dependencies (first time only)
pip install -r requirements.txt

# 5. Run migrations (first time or after schema changes)
alembic upgrade head

# 6. Start FastAPI (use 127.0.0.1 on Windows to avoid Docker conflict)
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

# 7. In a new terminal — run Flutter
cd ..
flutter run
```

---

*Generated for CV Nova v0.1.0 — Last updated: 2026-07-27*
