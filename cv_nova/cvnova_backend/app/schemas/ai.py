from pydantic import BaseModel, Field

from app.ai.enums import ContentType, Tone


class AIGenerateRequest(BaseModel):
    content_type: ContentType
    tone: Tone = Tone.PROFESSIONAL
    context: dict[str, str] = Field(default_factory=dict)
    model: str | None = None  # falls back to settings.OLLAMA_DEFAULT_MODEL


class AIGenerateResponse(BaseModel):
    content: str
    model: str
    content_type: ContentType
    tone: Tone


class AIModelInfo(BaseModel):
    name: str
    size_bytes: int | None = None
    parameter_size: str | None = None
    quantization: str | None = None
