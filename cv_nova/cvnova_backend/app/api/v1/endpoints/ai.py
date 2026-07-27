from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse

from app.ai.ollama_client import OllamaClient, OllamaUnavailableError, get_ollama_client
from app.api.deps import CurrentUser
from app.schemas.ai import AIGenerateRequest, AIGenerateResponse, AIModelInfo
from app.services.ai_service import AIService

router = APIRouter(prefix="/ai", tags=["ai"])

_UNAVAILABLE_DETAIL = (
    "Could not reach Ollama. Make sure it's running locally (`ollama serve`) "
    "and that at least one model has been pulled (`ollama pull llama3`)."
)


@router.get("/models", response_model=list[AIModelInfo])
async def list_models(
    current_user: CurrentUser,
    client: OllamaClient = Depends(get_ollama_client),
):
    """Auto-detects locally installed Ollama models, per the spec — the
    frontend's model switcher populates from this rather than a hardcoded
    list, so it always matches what's actually pulled."""
    service = AIService(client)
    try:
        return await service.list_models()
    except OllamaUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=_UNAVAILABLE_DETAIL
        ) from exc


@router.post("/generate", response_model=AIGenerateResponse)
async def generate(
    payload: AIGenerateRequest,
    current_user: CurrentUser,
    client: OllamaClient = Depends(get_ollama_client),
):
    """Non-streaming generation — waits for the full response before
    returning. Simpler for callers that don't need token-by-token UI, e.g.
    generating technical_skills or a short achievement line."""
    service = AIService(client)
    try:
        return await service.generate(payload)
    except OllamaUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=_UNAVAILABLE_DETAIL
        ) from exc


@router.post("/generate/stream")
async def generate_stream(
    payload: AIGenerateRequest,
    current_user: CurrentUser,
    client: OllamaClient = Depends(get_ollama_client),
):
    """Streaming generation — for longer content (summaries, bullet lists)
    where showing tokens as they arrive makes the wait feel much shorter.
    Plain chunked text/plain, not SSE — the client just appends each chunk
    as it arrives; there's no multiplexed event data to justify SSE's extra
    framing here.

    The first chunk is awaited *before* the StreamingResponse is created,
    so the common failure mode (Ollama not running at all) surfaces as a
    normal 503 rather than a 200 response that starts streaming and then
    dies — HTTP doesn't allow changing the status code after the response
    has started, so this is the only point a clean error status is possible.
    """
    service = AIService(client)
    generator = service.generate_stream(payload)

    try:
        first_chunk = await anext(generator, None)
    except OllamaUnavailableError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=_UNAVAILABLE_DETAIL
        ) from exc

    async def _stream():
        if first_chunk is not None:
            yield first_chunk
        try:
            async for chunk in generator:
                yield chunk
        except OllamaUnavailableError:
            # Failed mid-stream, after headers were already sent — the best
            # we can do is surface it in the body rather than a status code.
            yield f"\n\n[error] {_UNAVAILABLE_DETAIL}"

    return StreamingResponse(_stream(), media_type="text/plain")
