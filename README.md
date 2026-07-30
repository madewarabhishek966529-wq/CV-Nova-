# CVNova — Flutter Frontend

AI-powered resume builder & career assistant. Theme system, real
authentication, and now a full multi-resume editor wired to the backend's
`/resumes` CRUD API.

## Run it

```bash
flutter pub get
flutter run
```

Make sure the backend (`cvnova_backend/`) is running first — see its README.
**Android emulator only:** change `apiBaseUrl` in `lib/utils/constants.dart`
to `http://10.0.2.2:8000/api/v1`; `localhost` works as-is for iOS
simulator, web, and desktop.

**Note on verification:** no Flutter/Dart SDK was available in the sandbox
this was built in (no `pub.dev` network access either), so this was checked
by hand — every relative import resolves to a real file, every imported
package is declared in `pubspec.yaml`, and every Dart↔backend JSON key was
cross-checked field-by-field against the Pydantic schemas — but it has not
been run through `flutter analyze` or on a real device/simulator. Run
`flutter analyze` first thing after `pub get`; see "Known risk" below for
the one area most likely to need a fix.

## What's in this phase

```
lib/
  models/
    user.dart
    resume.dart              # Resume + every section item type, JSON keys match backend exactly
  services/
    api_client.dart  api_exceptions.dart  auth_service.dart  token_storage.dart
    resume_service.dart      # list/get/create/update/delete/duplicate against /resumes
  providers/
    auth_provider.dart  auth_state.dart  theme_provider.dart
    resume_list_provider.dart    # fetches + mutates the resume list
    resume_editor_provider.dart  # one resume being edited, debounced autosave (900ms)
  widgets/resume/
    tag_input.dart            # chip input — skills, interests
    bullet_list_editor.dart   # reorderable string list — experience/project bullets, custom sections
    editable_list_section.dart # generic reorderable add/edit/delete section — powers 9 of the 14 sections
    simple_sections.dart      # personal info, headline, summary, tag section (non-list sections)
    dialog_shell.dart         # shared dialog chrome
    dialogs/                  # one edit dialog per item type (experience, education, project,
                               # certification, achievement, language, reference, link, custom section)
  screens/resume/
    resume_list_screen.dart    # list, create, duplicate, delete, empty state
    resume_editor_screen.dart  # assembles all 14 sections, section-level drag reorder + hide/show
    resume_preview_screen.dart # live rendered preview, same provider instance as the editor
  components/                  # still reserved — see its README
```

## How the editor works

- **Section order & visibility** live on the `Resume` itself
  (`section_order`, `hidden_sections`) — dragging a section or tapping its
  eye icon mutates that array and autosaves, exactly like backend-side
  state, not local-only UI state.
- **Every section is one of two shapes**: a flat list of strings (skills,
  interests — `TagInput`) or a reorderable list of structured items
  (everything else — `EditableListSection<T>`, generic over the item type,
  with an item-specific edit dialog injected per section). Personal info,
  headline, and summary are the only true "singular" sections and get their
  own small widgets.
- **Autosave**: any edit calls `ResumeEditorNotifier.apply()`, which updates
  local state immediately (typing never waits on the network) and debounces
  a `PUT /resumes/{id}` by 900ms. Leaving the editor screen
  (`dispose()`) flushes any pending edit immediately so nothing is lost.
- **New item ids** are generated client-side
  (`DateTime.now().microsecondsSinceEpoch.toString()`) — the backend trusts
  client-generated ids within a resume the caller owns (see backend
  `resume_sections.py` docstring).

## Known risk — nested `ReorderableListView`

The section-level drag-reorder (outer list, in `resume_editor_screen.dart`)
contains sections that are themselves a `ReorderableListView` (inner list,
in `editable_list_section.dart`, for reordering items within a section).
This is a working, commonly-used Flutter pattern when the inner list uses
`shrinkWrap: true` + `NeverScrollableScrollPhysics()` (which it does here)
— but it's the one interaction in this phase that genuinely needs
hands-on testing rather than just a code read, since gesture-arena
conflicts between two nested drag-reorder lists are the kind of thing that
only shows up on a device. If dragging an item within a section feels off,
that's the first place to look.

## What's stubbed / not yet built

- **Live preview**: tap the eye icon in the editor's app bar. The preview
  screen watches the *same* `resumeEditorProvider(resumeId)` instance the
  editor mutates, so edits — including ones still mid-debounce, not yet
  saved to the server — show up immediately, no separate fetch or manual
  refresh. Renders as a single, clean document layout
  (`widgets/resume/preview/resume_preview.dart`) honoring section order and
  hidden sections; personal info and headline fold into the header the way
  every resume template treats them, rather than appearing as their own
  titled sections. This is the one, implicit visual template — a template
  *picker* with multiple distinct visual designs, and real PDF export via
  ReportLab on the backend, are separate future work (see "Template
  selection" below). The preview widget is written as a pure function of
  `Resume -> Widget` specifically so it can be reused as the visual
  reference when PDF export is built, without modification.
- **Undo/redo**: not built. Autosave debouncing plus the backend's future
  Resume Version History feature are the intended real undo mechanism
  (restore a prior version), rather than an in-memory undo stack — see
  backend README's "Resume Version Control" note.
- **Access-token refresh mid-request on 401**: still only happens at app
  startup (see previous phase's note) — resume screens will show a login
  prompt if the access token expires mid-session rather than silently
  refreshing. Worth fixing before this feels production-ready.
- Template selection / multiple visual templates: `template` field exists
  on the model and defaults to `'modern'`, but there's only one (implicit)
  visual treatment right now — no template picker UI.

## Design system

- **Color**: `ink` (#0C0E1B) / `paper` (#F6F5FB) surfaces; brand ramp is
  indigo → violet → amber (`#4A3AFF → #8B5CF6 → #F5A623`) — the app's score
  gradient, reused for every score/progress visual.
- **Type**: Space Grotesk (display), Inter (body), JetBrains Mono (scores/stats).
- **Signature element**: `ScoreRing` — reuse it for every future score
  visual (ATS score, resume score, skill graph) rather than inventing new
  indicators.

## Next phase

Ollama AI integration for AI-generated summaries/bullet points per the
original spec, then ATS scoring.


