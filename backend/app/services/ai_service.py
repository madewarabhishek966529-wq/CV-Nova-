from collections.abc import AsyncIterator

from app.ai.ollama_client import OllamaClient
from app.ai.prompts import build_prompt
from app.core.config import settings
from app.schemas.ai import AIGenerateRequest, AIGenerateResponse, AIModelInfo


class AIService:
    def __init__(self, client: OllamaClient):
        self._client = client

    def _resolve_model(self, requested: str | None) -> str:
        return requested or settings.OLLAMA_DEFAULT_MODEL

    async def generate(self, request: AIGenerateRequest) -> AIGenerateResponse:
        model = self._resolve_model(request.model)
        system, prompt = build_prompt(request.content_type, request.tone, request.context)
        content = await self._client.generate(model=model, system=system, prompt=prompt)
        return AIGenerateResponse(
            content=content,
            model=model,
            content_type=request.content_type,
            tone=request.tone,
        )

    async def generate_stream(self, request: AIGenerateRequest) -> AsyncIterator[str]:
        model = self._resolve_model(request.model)
        system, prompt = build_prompt(request.content_type, request.tone, request.context)
        async for chunk in self._client.generate_stream(model=model, system=system, prompt=prompt):
            yield chunk

    async def list_models(self) -> list[AIModelInfo]:
        raw_models = await self._client.list_models()
        return [
            AIModelInfo(
                name=m.get("name", "unknown"),
                size_bytes=m.get("size"),
                parameter_size=(m.get("details") or {}).get("parameter_size"),
                quantization=(m.get("details") or {}).get("quantization_level"),
            )
            for m in raw_models
        ]
