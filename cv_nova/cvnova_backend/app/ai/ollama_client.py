import json
from collections.abc import AsyncIterator

import httpx

from app.core.config import settings


class OllamaUnavailableError(Exception):
    """Ollama isn't reachable at OLLAMA_BASE_URL — most likely it isn't
    running (`ollama serve`) or no model has been pulled yet."""


class OllamaClient:
    """Thin async wrapper over Ollama's HTTP API. Ollama is expected to be
    running locally (or on the LAN) — this is not a cloud AI API, there is
    no API key. See app/ai/prompts.py for what gets sent, and
    app/services/ai_service.py for how this is used.
    """

    def __init__(self, base_url: str | None = None, timeout: float | None = None):
        self._base_url = (base_url or settings.OLLAMA_BASE_URL).rstrip("/")
        self._timeout = timeout or settings.OLLAMA_REQUEST_TIMEOUT_SECONDS

    async def list_models(self) -> list[dict]:
        """Calls GET /api/tags — the set of models the user has already
        pulled locally. Used to populate the model-switcher in the UI
        (auto-detect installed Ollama models, per the spec) rather than
        hardcoding a model list that may not match what's actually
        installed."""
        try:
            async with httpx.AsyncClient(base_url=self._base_url, timeout=self._timeout) as client:
                response = await client.get("/api/tags")
                response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OllamaUnavailableError(str(exc)) from exc

        return response.json().get("models", [])

    async def generate(self, *, model: str, system: str, prompt: str) -> str:
        """Non-streaming generation — waits for the full response."""
        try:
            async with httpx.AsyncClient(base_url=self._base_url, timeout=self._timeout) as client:
                response = await client.post(
                    "/api/generate",
                    json={"model": model, "system": system, "prompt": prompt, "stream": False},
                )
                response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OllamaUnavailableError(str(exc)) from exc

        return response.json().get("response", "").strip()

    async def generate_stream(
        self, *, model: str, system: str, prompt: str
    ) -> AsyncIterator[str]:
        """Streaming generation — yields text chunks as Ollama produces them.
        Ollama's streaming format is newline-delimited JSON objects, each
        with a "response" chunk and a "done" flag; this yields just the text
        chunks, in order, and stops when "done" is true."""
        try:
            async with httpx.AsyncClient(base_url=self._base_url, timeout=self._timeout) as client:
                async with client.stream(
                    "POST",
                    "/api/generate",
                    json={"model": model, "system": system, "prompt": prompt, "stream": True},
                ) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if not line.strip():
                            continue
                        payload = json.loads(line)
                        chunk = payload.get("response", "")
                        if chunk:
                            yield chunk
                        if payload.get("done"):
                            break
        except httpx.HTTPError as exc:
            raise OllamaUnavailableError(str(exc)) from exc


def get_ollama_client() -> OllamaClient:
    """FastAPI dependency — overridden in tests with a fake client so tests
    never make a real network call to a local Ollama instance."""
    return OllamaClient()
