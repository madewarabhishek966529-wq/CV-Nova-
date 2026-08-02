import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ScoreBreakdown(BaseModel):
    overall: int
    formatting: int
    keywords: int
    impact: int


class AnalysisFeedback(BaseModel):
    strengths: list[str] = Field(default_factory=list)
    weaknesses: list[str] = Field(default_factory=list)
    missing_keywords: list[str] = Field(default_factory=list)
    suggestions: list[str] = Field(default_factory=list)


class ResumeAnalysisSummary(BaseModel):
    """Lightweight shape for list views — mirrors ResumeSummary's role for
    resumes: no extracted_text, just enough to render a history list."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    filename: str
    word_count: int
    score: ScoreBreakdown
    created_at: datetime


class ResumeAnalysisRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    filename: str
    word_count: int
    score: ScoreBreakdown
    feedback: AnalysisFeedback
    created_at: datetime
