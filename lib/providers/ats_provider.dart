import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resume_analysis.dart';
import '../services/ats_service.dart';

enum AtsLoadStatus { idle, loading, loaded, error }

class AtsState {
  const AtsState({
    this.latest,
    this.history = const [],
    this.loadStatus = AtsLoadStatus.idle,
    this.analyzing = false,
    this.error,
  });

  final ResumeAnalysis? latest;
  final List<ResumeAnalysisSummary> history;
  final AtsLoadStatus loadStatus;
  final bool analyzing;
  final String? error;

  AtsState copyWith({
    ResumeAnalysis? latest,
    bool clearLatest = false,
    List<ResumeAnalysisSummary>? history,
    AtsLoadStatus? loadStatus,
    bool? analyzing,
    String? error,
  }) =>
      AtsState(
        latest: clearLatest ? null : (latest ?? this.latest),
        history: history ?? this.history,
        loadStatus: loadStatus ?? this.loadStatus,
        analyzing: analyzing ?? this.analyzing,
        error: error,
      );
}

class AtsNotifier extends StateNotifier<AtsState> {
  AtsNotifier({AtsService? service})
      : _service = service ?? AtsService(),
        super(const AtsState());

  final AtsService _service;

  /// Loads both the latest score (for the dashboard card) and the full
  /// history in one pass — call when the dashboard or analyzer screen
  /// first mounts.
  Future<void> load() async {
    state = state.copyWith(loadStatus: AtsLoadStatus.loading, error: null);
    try {
      final results = await Future.wait([_service.latest(), _service.history()]);
      state = state.copyWith(
        latest: results[0] as ResumeAnalysis?,
        clearLatest: results[0] == null,
        history: results[1] as List<ResumeAnalysisSummary>,
        loadStatus: AtsLoadStatus.loaded,
      );
    } catch (e) {
      state = state.copyWith(loadStatus: AtsLoadStatus.error, error: e.toString());
    }
  }

  Future<ResumeAnalysis?> analyze({
    required List<int> fileBytes,
    required String filename,
    List<String>? targetKeywords,
  }) async {
    state = state.copyWith(analyzing: true, error: null);
    try {
      final result = await _service.analyze(
        fileBytes: fileBytes,
        filename: filename,
        targetKeywords: targetKeywords,
      );
      state = state.copyWith(latest: result, analyzing: false);
      unawaited(load()); // refresh history in the background
      return result;
    } catch (e) {
      state = state.copyWith(analyzing: false, error: e.toString());
      return null;
    }
  }
}

final atsProvider = StateNotifierProvider<AtsNotifier, AtsState>((ref) => AtsNotifier());
