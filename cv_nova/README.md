# CVNova — Flutter Skeleton (Phase 1)

AI-powered resume builder & career assistant. This is the frontend
foundation: theme system, routing, and the reusable components everything
else builds on. No backend calls yet — auth screens simulate a request and
route straight to the dashboard.

## Run it

```bash
flutter pub get
flutter run
```

## What's in this phase

```
lib/
  main.dart                 # entry point — ProviderScope + MaterialApp.router
  theme/
    app_colors.dart         # color tokens (see "Design system" below)
    app_typography.dart     # Space Grotesk / Inter / JetBrains Mono roles
    app_gradients.dart      # hero + score gradients, ambient blobs
    app_theme.dart          # ThemeData assembly (light + dark)
  providers/
    theme_provider.dart     # Riverpod StateNotifier, persisted via shared_preferences
  routes/
    route_names.dart        # single source of truth for path strings
    app_router.dart         # GoRouter config
  widgets/common/
    glass_card.dart         # standard glassmorphic surface
    gradient_button.dart    # primary CTA button
    score_ring.dart         # signature animated gradient progress ring
  screens/
    splash/                 # animated splash, auto-navigates to /login
    auth/                   # login_screen.dart, signup_screen.dart (validated forms)
    dashboard/               # placeholder dashboard showing the components together
  components/  services/  models/   # reserved for upcoming phases (see READMEs inside)
```

## Design system

- **Color**: `ink` (#0C0E1B) / `paper` (#F6F5FB) surfaces; brand ramp is
  indigo → violet → amber (`#4A3AFF → #8B5CF6 → #F5A623`). That ramp is not
  just decorative — it's the app's **score gradient**, reused for every
  score/progress visual (resume score, ATS score, skill graph nodes) so a
  color always means the same thing everywhere in the app.
- **Type**: Space Grotesk for display/headlines, Inter for body copy,
  JetBrains Mono reserved specifically for numeric/measured content (scores,
  stats, dates) — see `AppTypography.data()`.
- **Signature element**: `ScoreRing` — a custom-painted animated sweep
  gradient. It's the one recurring visual identity piece; reuse it rather
  than inventing new progress indicators as later phases add more scores.

## Next phases

1. FastAPI + PostgreSQL backend, JWT auth — then wire `login_screen.dart` /
   `signup_screen.dart` to real endpoints (currently stubbed with a
   `TODO(auth-phase)` marker and a fake delay).
2. Resume data models + CRUD, multi-resume editor UI.
3. Ollama AI integration (summary/bullet generation, streaming).
4. ATS scoring, skill gap analysis, templates/export, portfolio generator,
   interview prep, job match analyzer, career roadmap, admin panel — per the
   original CVNova spec.
