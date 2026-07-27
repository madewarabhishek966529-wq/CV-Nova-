import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

USER_A = {"email": "a@example.com", "password": "supersecure123", "full_name": "User A"}
USER_B = {"email": "b@example.com", "password": "supersecure123", "full_name": "User B"}


async def _auth_headers(client: AsyncClient, user: dict) -> dict:
    await client.post("/api/v1/auth/signup", json=user)
    login = await client.post(
        "/api/v1/auth/login", json={"email": user["email"], "password": user["password"]}
    )
    token = login.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


async def test_create_resume_becomes_primary(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    response = await client.post(
        "/api/v1/resumes", json={"title": "Backend Engineer Resume"}, headers=headers
    )
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Backend Engineer Resume"
    assert body["is_primary"] is True
    assert body["experience"] == []
    assert body["section_order"][0] == "personal_info"


async def test_list_resumes_returns_summary_shape(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    await client.post("/api/v1/resumes", json={"title": "Resume 1"}, headers=headers)
    await client.post("/api/v1/resumes", json={"title": "Resume 2"}, headers=headers)

    response = await client.get("/api/v1/resumes", headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 2
    assert "experience" not in body[0]  # summary shape, not full document
    assert {r["title"] for r in body} == {"Resume 1", "Resume 2"}


async def test_get_resume_by_id(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    created = await client.post("/api/v1/resumes", json={"title": "My Resume"}, headers=headers)
    resume_id = created.json()["id"]

    response = await client.get(f"/api/v1/resumes/{resume_id}", headers=headers)
    assert response.status_code == 200
    assert response.json()["id"] == resume_id


async def test_get_resume_not_owned_returns_404(client: AsyncClient):
    headers_a = await _auth_headers(client, USER_A)
    created = await client.post("/api/v1/resumes", json={"title": "A's Resume"}, headers=headers_a)
    resume_id = created.json()["id"]

    headers_b = await _auth_headers(client, USER_B)
    response = await client.get(f"/api/v1/resumes/{resume_id}", headers=headers_b)
    assert response.status_code == 404


async def test_update_resume_full_replace(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    created = await client.post("/api/v1/resumes", json={"title": "Draft"}, headers=headers)
    resume_id = created.json()["id"]
    full = created.json()

    full["headline"] = "Senior Flutter Developer"
    full["professional_summary"] = "Builder of things."
    full["skills"] = ["Flutter", "Dart", "Riverpod"]
    full["experience"] = [
        {
            "id": "exp-1",
            "company": "Dream Webies",
            "role": "Flutter Developer Intern",
            "location": "Remote",
            "start_date": "2025-01",
            "end_date": "2025-06",
            "is_current": False,
            "bullets": ["Built production Flutter apps", "Shipped 3 features"],
        }
    ]

    response = await client.put(f"/api/v1/resumes/{resume_id}", json=full, headers=headers)
    assert response.status_code == 200
    body = response.json()
    assert body["headline"] == "Senior Flutter Developer"
    assert len(body["experience"]) == 1
    assert body["experience"][0]["company"] == "Dream Webies"
    assert body["skills"] == ["Flutter", "Dart", "Riverpod"]


async def test_update_rejects_unknown_section_key(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    created = await client.post("/api/v1/resumes", json={"title": "Draft"}, headers=headers)
    resume_id = created.json()["id"]
    full = created.json()
    full["section_order"] = ["not_a_real_section"]

    response = await client.put(f"/api/v1/resumes/{resume_id}", json=full, headers=headers)
    assert response.status_code == 422


async def test_second_resume_marked_primary_unsets_first(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    first = await client.post("/api/v1/resumes", json={"title": "First"}, headers=headers)
    second = await client.post("/api/v1/resumes", json={"title": "Second"}, headers=headers)

    second_full = second.json()
    second_full["is_primary"] = True
    await client.put(f"/api/v1/resumes/{second.json()['id']}", json=second_full, headers=headers)

    first_check = await client.get(f"/api/v1/resumes/{first.json()['id']}", headers=headers)
    assert first_check.json()["is_primary"] is False


async def test_duplicate_resume_copies_content(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    created = await client.post("/api/v1/resumes", json={"title": "Original"}, headers=headers)
    resume_id = created.json()["id"]
    full = created.json()
    full["skills"] = ["Python", "FastAPI"]
    await client.put(f"/api/v1/resumes/{resume_id}", json=full, headers=headers)

    response = await client.post(f"/api/v1/resumes/{resume_id}/duplicate", headers=headers)
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Original (Copy)"
    assert body["skills"] == ["Python", "FastAPI"]
    assert body["is_primary"] is False
    assert body["id"] != resume_id


async def test_delete_resume_promotes_new_primary(client: AsyncClient):
    headers = await _auth_headers(client, USER_A)
    first = await client.post("/api/v1/resumes", json={"title": "First"}, headers=headers)
    second = await client.post("/api/v1/resumes", json={"title": "Second"}, headers=headers)

    delete_response = await client.delete(
        f"/api/v1/resumes/{first.json()['id']}", headers=headers
    )
    assert delete_response.status_code == 204

    remaining = await client.get(f"/api/v1/resumes/{second.json()['id']}", headers=headers)
    assert remaining.json()["is_primary"] is True


async def test_resumes_require_auth(client: AsyncClient):
    response = await client.get("/api/v1/resumes")
    assert response.status_code == 401
