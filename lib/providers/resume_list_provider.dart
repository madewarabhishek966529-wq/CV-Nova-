import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resume.dart';
import '../services/resume_service.dart';

class ResumeListState {
  const ResumeListState({
    this.resumes = const [],
    this.loading = false,
    this.error,
  });

  final List<ResumeSummary> resumes;
  final bool loading;
  final String? error;

  ResumeListState copyWith({List<ResumeSummary>? resumes, bool? loading, String? error}) =>
      ResumeListState(
        resumes: resumes ?? this.resumes,
        loading: loading ?? this.loading,
        error: error,
      );
}

class ResumeListNotifier extends StateNotifier<ResumeListState> {
  ResumeListNotifier({ResumeService? service})
      : _service = service ?? ResumeService(),
        super(const ResumeListState());

  final ResumeService _service;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resumes = await _service.list();
      state = state.copyWith(resumes: resumes, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<Resume?> create({required String title, String template = 'modern'}) async {
    try {
      final resume = await _service.create(title: title, template: template);
      await load();
      return resume;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> delete(String id) async {
    // Optimistic removal — restored by load() if the request fails.
    final previous = state.resumes;
    state = state.copyWith(resumes: previous.where((r) => r.id != id).toList());
    try {
      await _service.delete(id);
    } catch (e) {
      state = state.copyWith(resumes: previous, error: e.toString());
    }
  }

  Future<void> duplicate(String id) async {
    try {
      await _service.duplicate(id);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final resumeListProvider = StateNotifierProvider<ResumeListNotifier, ResumeListState>(
  (ref) => ResumeListNotifier(),
);
