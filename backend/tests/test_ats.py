import io

import pytest
from httpx import AsyncClient
from reportlab.lib.pagesizes import LETTER
from reportlab.pdfgen import canvas

pytestmark = pytest.mark.asyncio


def _make_pdf(lines: list[str]) -> bytes:
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=LETTER)
    y = 750
    for line in lines:
        c.drawString(50, y, line)
        y -= 16
        if y < 50:
            c.showPage()
            y = 750
    c.save()
    return buffer.getvalue()


_STRONG_RESUME_LINES = [
    "Jordan Rivera",
    "jordan.rivera@example.com | (555) 123-4567",
    "",
    "Summary",
    "Backend engineer focused on distributed systems and developer tooling.",
    "",
    "Experience",
    "- Led migration of 40 microservices to Kubernetes, reducing deploy time by 65%",
    "- Built a Python data pipeline processing 2M events per day",
    "- Reduced API latency by 30% through caching and query optimization",
    "- Managed a team of 4 engineers delivering on a quarterly roadmap",
    "- Designed a CI/CD system that increased release frequency by 3x",
    "- Implemented automated testing, increasing coverage from 40% to 85%",
    "",
    "Education",
    "B.S. Computer Science, State University",
    "",
    "Skills",
    "Python, SQL, AWS, Docker, Kubernetes, React, REST APIs, Agile",
    "",
    "Projects",
    "Open-source contributor to several Python data tooling libraries",
]

_WEAK_RESUME_LINES = [
    "Sam",
    "Worked at a company doing stuff with computers.",
    "Was responsible for various tasks.",
    "Helped with things.",
]


async def test_analyze_strong_resume_scores_well(client: AsyncClient):
    pdf_bytes = _make_pdf(_STRONG_RESUME_LINES)
    response = await client.post(
        "/api/v1/ats/analyze",
        files={"file": ("resume.pdf", pdf_bytes, "application/pdf")},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["filename"] == "resume.pdf"
    assert body["word_count"] > 0
    assert body["score"]["overall"] >= 60
    assert body["score"]["impact"] >= 50
    assert isinstance(body["feedback"]["strengths"], list)
    assert len(body["feedback"]["strengths"]) > 0


async def test_analyze_weak_resume_scores_lower_and_has_suggestions(client: AsyncClient):
    pdf_bytes = _make_pdf(_WEAK_RESUME_LINES)
    response = await client.post(
        "/api/v1/ats/analyze",
        files={"file": ("thin.pdf", pdf_bytes, "application/pdf")},
    )
    assert response.status_code == 201
    body = response.json()
    assert len(body["feedback"]["suggestions"]) > 0


async def test_analyze_rejects_non_pdf(client: AsyncClient):
    response = await client.post(
        "/api/v1/ats/analyze",
        files={"file": ("resume.txt", b"just plain text", "text/plain")},
    )
    assert response.status_code == 415


async def test_analyze_rejects_unreadable_pdf(client: AsyncClient):
    response = await client.post(
        "/api/v1/ats/analyze",
        files={"file": ("resume.pdf", b"%PDF-1.4 not actually a real pdf", "application/pdf")},
    )
    assert response.status_code == 422


async def test_target_keywords_affect_score(client: AsyncClient):
    pdf_bytes = _make_pdf(_STRONG_RESUME_LINES)

    matching = await client.post(
        "/api/v1/ats/analyze",
        data={"target_keywords": "python,kubernetes,docker"},
        files={"file": ("resume.pdf", pdf_bytes, "application/pdf")},
    )
    nonmatching = await client.post(
        "/api/v1/ats/analyze",
        data={"target_keywords": "cobol,fortran,mainframe"},
        files={"file": ("resume.pdf", pdf_bytes, "application/pdf")},
    )

    assert matching.json()["score"]["keywords"] > nonmatching.json()["score"]["keywords"]
    assert set(nonmatching.json()["feedback"]["missing_keywords"]) == {"cobol", "fortran", "mainframe"}


async def test_list_and_latest_and_get_by_id(client: AsyncClient):
    pdf_bytes = _make_pdf(_STRONG_RESUME_LINES)
    created = await client.post(
        "/api/v1/ats/analyze",
        files={"file": ("resume.pdf", pdf_bytes, "application/pdf")},
    )
    analysis_id = created.json()["id"]

    listing = await client.get("/api/v1/ats/analyses")
    assert listing.status_code == 200
    assert len(listing.json()) == 1
    assert "feedback" not in listing.json()[0]  # summary shape

    latest = await client.get("/api/v1/ats/analyses/latest")
    assert latest.status_code == 200
    assert latest.json()["id"] == analysis_id

    by_id = await client.get(f"/api/v1/ats/analyses/{analysis_id}")
    assert by_id.status_code == 200
    assert by_id.json()["id"] == analysis_id


async def test_latest_returns_404_when_no_analyses_yet(client: AsyncClient):
    response = await client.get("/api/v1/ats/analyses/latest")
    assert response.status_code == 404
