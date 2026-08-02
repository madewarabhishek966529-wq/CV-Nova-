import uuid

import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_create_resume_becomes_primary(client: AsyncClient):
    response = await client.post("/api/v1/resumes", json={"title": "Backend Engineer Resume"})
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Backend Engineer Resume"
    assert body["is_primary"] is True
    assert body["experience"] == []
    assert body["section_order"][0] == "personal_info"


async def test_list_resumes_returns_summary_shape(client: AsyncClient):
    await client.post("/api/v1/resumes", json={"title": "Resume 1"})
    await client.post("/api/v1/resumes", json={"title": "Resume 2"})

    response = await client.get("/api/v1/resumes")
    assert response.status_code == 200
    body = response.json()
    assert len(body) == 2
    assert "experience" not in body[0]  # summary shape, not full document
    assert {r["title"] for r in body} == {"Resume 1", "Resume 2"}


async def test_get_resume_by_id(client: AsyncClient):
    created = await client.post("/api/v1/resumes", json={"title": "My Resume"})
    resume_id = created.json()["id"]

    response = await client.get(f"/api/v1/resumes/{resume_id}")
    assert response.status_code == 200
    assert response.json()["id"] == resume_id


async def test_get_nonexistent_resume_returns_404(client: AsyncClient):
    response = await client.get(f"/api/v1/resumes/{uuid.uuid4()}")
    assert response.status_code == 404


async def test_update_resume_full_replace(client: AsyncClient):
    created = await client.post("/api/v1/resumes", json={"title": "Draft"})
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

    response = await client.put(f"/api/v1/resumes/{resume_id}", json=full)
    assert response.status_code == 200
    body = response.json()
    assert body["headline"] == "Senior Flutter Developer"
    assert len(body["experience"]) == 1
    assert body["experience"][0]["company"] == "Dream Webies"
    assert body["skills"] == ["Flutter", "Dart", "Riverpod"]


async def test_update_rejects_unknown_section_key(client: AsyncClient):
    created = await client.post("/api/v1/resumes", json={"title": "Draft"})
    resume_id = created.json()["id"]
    full = created.json()
    full["section_order"] = ["not_a_real_section"]

    response = await client.put(f"/api/v1/resumes/{resume_id}", json=full)
    assert response.status_code == 422


async def test_second_resume_marked_primary_unsets_first(client: AsyncClient):
    first = await client.post("/api/v1/resumes", json={"title": "First"})
    second = await client.post("/api/v1/resumes", json={"title": "Second"})

    second_full = second.json()
    second_full["is_primary"] = True
    await client.put(f"/api/v1/resumes/{second.json()['id']}", json=second_full)

    first_check = await client.get(f"/api/v1/resumes/{first.json()['id']}")
    assert first_check.json()["is_primary"] is False


async def test_duplicate_resume_copies_content(client: AsyncClient):
    created = await client.post("/api/v1/resumes", json={"title": "Original"})
    resume_id = created.json()["id"]
    full = created.json()
    full["skills"] = ["Python", "FastAPI"]
    await client.put(f"/api/v1/resumes/{resume_id}", json=full)

    response = await client.post(f"/api/v1/resumes/{resume_id}/duplicate")
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "Original (Copy)"
    assert body["skills"] == ["Python", "FastAPI"]
    assert body["is_primary"] is False
    assert body["id"] != resume_id


async def test_delete_resume_promotes_new_primary(client: AsyncClient):
    first = await client.post("/api/v1/resumes", json={"title": "First"})
    second = await client.post("/api/v1/resumes", json={"title": "Second"})

    delete_response = await client.delete(f"/api/v1/resumes/{first.json()['id']}")
    assert delete_response.status_code == 204

    remaining = await client.get(f"/api/v1/resumes/{second.json()['id']}")
    assert remaining.json()["is_primary"] is True
