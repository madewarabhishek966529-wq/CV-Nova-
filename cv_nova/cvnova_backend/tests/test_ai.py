from collections.abc import AsyncIterator

import pytest
from httpx import AsyncClient

from app.ai.ollama_client import OllamaUnavailableError, get_ollama_client
from app.main import app

pytestmark = pytest.mark.asyncio

USER = {"email": "ai-user@example.com", "password": "supersecure123", "full_name": "AI User"}


class FakeOllamaClient:
    """Records what it was called with, returns canned output — no network."""

    def __init__(self, *, fail: bool = False):
        self.fail = fail
        self.last_call: dict | None = None

    async def list_models(self):
        if self.fail:
            raise OllamaUnavailableError("connection refused")
        return [
            {
                "name": "llama3:latest",
                "size": 4700000000,
                "details": {"parameter_size": "8B", "quantization_level": "Q4_0"},
            }
        ]

    async def generate(self, *, model: str, system: str, prompt: str) -> str:
        if self.fail:
            raise OllamaUnavailableError("connection refused")
        self.last_call = {"model": model, "system": system, "prompt": prompt}
        return "Generated resume content."

    async def generate_stream(self, *, model: str, system: str, prompt: str) -> AsyncIterator[str]:
        if self.fail:
            raise OllamaUnavailableError("connection refused")
        self.last_call = {"model": model, "system": system, "prompt": prompt}
        for chunk in ["Built ", "a production ", "Flutter app."]:
            yield chunk


async def _auth_headers(client: AsyncClient) -> dict:
    await client.post("/api/v1/auth/signup", json=USER)
    login = await client.post(
        "/api/v1/auth/login", json={"email": USER["email"], "password": USER["password"]}
    )
    token = login.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(autouse=True)
def _clear_ollama_override():
    yield
    app.dependency_overrides.pop(get_ollama_client, None)


async def test_generate_returns_content(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.post(
        "/api/v1/ai/generate",
        json={
            "content_type": "experience_bullets",
            "tone": "professional",
            "context": {"role": "Flutter Developer", "company": "Dream Webies", "notes": "built apps"},
        },
        headers=headers,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["content"] == "Generated resume content."
    assert body["model"] == "llama3"  # falls back to OLLAMA_DEFAULT_MODEL
    assert body["content_type"] == "experience_bullets"
    assert body["tone"] == "professional"


async def test_generate_passes_context_into_prompt(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    await client.post(
        "/api/v1/ai/generate",
        json={
            "content_type": "summary",
            "tone": "executive",
            "context": {"role": "Engineering Manager", "years_experience": "8"},
        },
        headers=headers,
    )

    assert fake.last_call is not None
    assert "Engineering Manager" in fake.last_call["prompt"]
    assert "8" in fake.last_call["prompt"]
    assert "executive" in fake.last_call["system"].lower()


async def test_generate_uses_requested_model_override(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.post(
        "/api/v1/ai/generate",
        json={"content_type": "achievement", "context": {"notes": "won a hackathon"}, "model": "mistral"},
        headers=headers,
    )
    assert response.json()["model"] == "mistral"


async def test_generate_rejects_invalid_content_type(client: AsyncClient):
    headers = await _auth_headers(client)
    response = await client.post(
        "/api/v1/ai/generate",
        json={"content_type": "not_a_real_type", "context": {}},
        headers=headers,
    )
    assert response.status_code == 422


async def test_generate_returns_503_when_ollama_unavailable(client: AsyncClient):
    fake = FakeOllamaClient(fail=True)
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.post(
        "/api/v1/ai/generate",
        json={"content_type": "summary", "context": {}},
        headers=headers,
    )
    assert response.status_code == 503


async def test_generate_requires_auth(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake

    response = await client.post(
        "/api/v1/ai/generate", json={"content_type": "summary", "context": {}}
    )
    assert response.status_code == 401


async def test_generate_stream_returns_full_text(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.post(
        "/api/v1/ai/generate/stream",
        json={"content_type": "project_description", "context": {"project_name": "CVNova"}},
        headers=headers,
    )
    assert response.status_code == 200
    assert response.text == "Built a production Flutter app."


async def test_generate_stream_returns_503_on_immediate_failure(client: AsyncClient):
    fake = FakeOllamaClient(fail=True)
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.post(
        "/api/v1/ai/generate/stream",
        json={"content_type": "summary", "context": {}},
        headers=headers,
    )
    assert response.status_code == 503


async def test_list_models_returns_parsed_models(client: AsyncClient):
    fake = FakeOllamaClient()
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.get("/api/v1/ai/models", headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body[0]["name"] == "llama3:latest"
    assert body[0]["parameter_size"] == "8B"


async def test_list_models_returns_503_when_ollama_unavailable(client: AsyncClient):
    fake = FakeOllamaClient(fail=True)
    app.dependency_overrides[get_ollama_client] = lambda: fake
    headers = await _auth_headers(client)

    response = await client.get("/api/v1/ai/models", headers=headers)
    assert response.status_code == 503
