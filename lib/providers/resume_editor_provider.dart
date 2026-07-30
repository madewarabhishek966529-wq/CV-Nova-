import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resume.dart';
import '../services/resume_service.dart';
import 'auth_provider.dart';

enum SaveStatus { idle, saving, saved, error }

class ResumeEditorState {
  const ResumeEditorState({
    this.resume,
    this.loading = true,
    this.saveStatus = SaveStatus.idle,
    this.error,
  });

  final Resume? resume;
  final bool loading;
  final SaveStatus saveStatus;
  final String? error;

  ResumeEditorState copyWith({
    Resume? resume,
    bool? loading,
    SaveStatus? saveStatus,
    String? error,
  }) =>
      ResumeEditorState(
        resume: resume ?? this.resume,
        loading: loading ?? this.loading,
        saveStatus: saveStatus ?? this.saveStatus,
        error: error,
      );
}

/// Owns one resume document while it's being edited. Every mutating method
/// (updateHeadline, addExperience, reorderSections, ...) applies the change
/// to local state immediately (instant UI feedback) and schedules a
/// debounced autosave — the editor never blocks typing on a network call.
class ResumeEditorNotifier extends StateNotifier<ResumeEditorState> {
  ResumeEditorNotifier(this._ref, this.resumeId, {ResumeService? service})
      : _service = service ?? ResumeService(),
        super(const ResumeEditorState()) {
    _load();
  }

  final Ref _ref;
  final String resumeId;
  final ResumeService _service;
  Timer? _debounce;

  String? get _token => _ref.read(authProvider).accessToken;

  Future<void> _load() async {
    final token = _token;
    if (token == null) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final resume = await _service.get(resumeId, token);
      state = state.copyWith(resume: resume, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Every section editor calls this with a pure transform of the current
  /// resume. Keeps all mutation logic in the model layer / call sites
  /// rather than duplicating field-by-field setters here.
  void apply(Resume Function(Resume current) updater) {
    final current = state.resume;
    if (current == null) return;
    state = state.copyWith(resume: updater(current));
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), _save);
  }

  Future<void> _save() async {
    final token = _token;
    final resume = state.resume;
    if (token == null || resume == null) return;

    state = state.copyWith(saveStatus: SaveStatus.saving);
    try {
      final saved = await _service.update(resume, token);
      state = state.copyWith(resume: saved, saveStatus: SaveStatus.saved);
    } catch (e) {
      state = state.copyWith(saveStatus: SaveStatus.error, error: e.toString());
    }
  }

  /// Forces an immediate save, bypassing the debounce — call when leaving
  /// the editor screen so no pending edit is lost.
  Future<void> saveNow() async {
    _debounce?.cancel();
    await _save();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final resumeEditorProvider =
    StateNotifierProvider.family<ResumeEditorNotifier, ResumeEditorState, String>(
  (ref, resumeId) => ResumeEditorNotifier(ref, resumeId),
);
