import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

SIGNUP_PAYLOAD = {
    "email": "omkar@example.com",
    "password": "supersecure123",
    "full_name": "Omkar Madewar",
}


async def test_signup_creates_user(client: AsyncClient):
    response = await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    assert response.status_code == 201
    body = response.json()
    assert body["email"] == SIGNUP_PAYLOAD["email"]
    assert body["full_name"] == SIGNUP_PAYLOAD["full_name"]
    assert "hashed_password" not in body


async def test_signup_rejects_duplicate_email(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    response = await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    assert response.status_code == 409


async def test_signup_rejects_short_password(client: AsyncClient):
    payload = {**SIGNUP_PAYLOAD, "password": "short"}
    response = await client.post("/api/v1/auth/signup", json=payload)
    assert response.status_code == 422


async def test_login_returns_tokens(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": SIGNUP_PAYLOAD["password"]},
    )
    assert response.status_code == 200
    body = response.json()
    assert "access_token" in body
    assert "refresh_token" in body
    assert body["token_type"] == "bearer"


async def test_login_rejects_wrong_password(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)

    response = await client.post(
        "/api/v1/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": "wrongpassword"},
    )
    assert response.status_code == 401


async def test_me_requires_token(client: AsyncClient):
    response = await client.get("/api/v1/users/me")
    assert response.status_code == 401


async def test_me_returns_current_user(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": SIGNUP_PAYLOAD["password"]},
    )
    access_token = login_response.json()["access_token"]

    response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == SIGNUP_PAYLOAD["email"]


async def test_refresh_issues_new_access_token(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": SIGNUP_PAYLOAD["password"]},
    )
    refresh_token = login_response.json()["refresh_token"]

    response = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": refresh_token}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()


async def test_refresh_rejects_access_token(client: AsyncClient):
    await client.post("/api/v1/auth/signup", json=SIGNUP_PAYLOAD)
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"email": SIGNUP_PAYLOAD["email"], "password": SIGNUP_PAYLOAD["password"]},
    )
    access_token = login_response.json()["access_token"]

    # An access token used where a refresh token is expected must be rejected.
    response = await client.post(
        "/api/v1/auth/refresh", json={"refresh_token": access_token}
    )
    assert response.status_code == 401
