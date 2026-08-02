"""PDF text extraction — the only place pypdf is imported. Isolated behind
a narrow function so the scoring logic and service layer never deal with
the PDF library directly.
"""

import io

from pypdf import PdfReader
from pypdf.errors import PdfReadError


class UnreadablePdfError(Exception):
    """Raised when the uploaded file isn't a PDF pypdf can parse, or has no
    extractable text (e.g. a scanned image with no text layer)."""


def extract_text(file_bytes: bytes) -> str:
    try:
        reader = PdfReader(io.BytesIO(file_bytes))
    except PdfReadError as exc:
        raise UnreadablePdfError("File is not a valid PDF") from exc

    if reader.is_encrypted:
        # Try an empty password — some exporters mark PDFs encrypted with
        # zero-length owner passwords purely to set permissions.
        try:
            reader.decrypt("")
        except Exception as exc:
            raise UnreadablePdfError("PDF is password-protected") from exc

    pages_text = []
    for page in reader.pages:
        try:
            pages_text.append(page.extract_text() or "")
        except Exception:
            # A single malformed page shouldn't sink the whole extraction.
            continue

    text = "\n".join(pages_text).strip()
    if not text:
        raise UnreadablePdfError(
            "No extractable text found — this may be a scanned image without a text layer"
        )
    return text
