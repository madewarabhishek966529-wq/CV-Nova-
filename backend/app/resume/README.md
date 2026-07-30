Note: the core Resume CRUD (models, schemas, repository, service, endpoints)
lives in the standard layered locations — app/models/resume.py,
app/schemas/resume.py + resume_sections.py, app/repositories/resume_repository.py,
app/services/resume_service.py, app/api/v1/endpoints/resumes.py — not in
this folder. This folder is reserved for resume-specific *domain logic*
that doesn't fit the standard CRUD layers: PDF/DOCX rendering per template,
resume scoring internals, version diffing, etc. (upcoming phases).
