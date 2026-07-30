#!/usr/bin/env bash
# ============================================================
# CV Nova Backend — Quick Start Script
# ============================================================
# Run this from the backend/ directory:
#   cd backend && bash start.sh
#
# Prerequisites:
#   - Docker Desktop running
#   - Python 3.11+ with venv support
# ============================================================

set -e

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BACKEND_DIR"

echo "🐳 Starting PostgreSQL and Redis via Docker Compose..."
docker compose up -d
echo "⏳ Waiting for Postgres to be healthy..."
until docker compose exec postgres pg_isready -U cvnova > /dev/null 2>&1; do
  sleep 1
done
echo "✅ Postgres ready."

echo "🐍 Setting up Python virtual environment..."
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
fi
source .venv/bin/activate

echo "📦 Installing Python dependencies..."
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

echo "🗄️  Running Alembic migrations..."
alembic upgrade head

echo "🚀 Starting FastAPI server on http://localhost:8000 ..."
echo "   Docs available at http://localhost:8000/docs (DEBUG=true)"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
