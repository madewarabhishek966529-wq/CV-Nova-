# CVNova — Architecture & Setup Notes

CVNova is a **standalone, offline-first application** built entirely with Flutter. 

## Key Architectural Decisions

1. **No External Backend or Docker Required**:
   - The backend and Docker containers have been completely removed.
   - All resume data is persistently managed on-device via local storage (`shared_preferences`).
   - Resumes support full CRUD (Create, Read, Update, Delete, Duplicate) and section reordering.

2. **Real-World On-Device ATS Scoring**:
   - Native PDF text extraction using `syncfusion_flutter_pdf`.
   - Deterministic ATS evaluation algorithm (`lib/services/ats_scorer.dart`) checking:
     - **Formatting**: Length, essential headers, and contact information.
     - **Impact**: Action verbs (`led`, `built`, `optimized`, etc.) and quantified metrics.
     - **Keywords**: Target job keywords matching or generic industry keyword coverage.
   - Saves historical ATS reports locally so you can track your resume improvements over time.

3. **Multiplatform & Offline**:
   - Zero network latency, full offline functionality, and complete user data privacy.

## Getting Started

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run test suite
flutter test

# 3. Launch on physical device or emulator
flutter run
```
