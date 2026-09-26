import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume_analysis.dart';
import 'ats_scorer.dart';
import 'pdf_extractor.dart';

class AtsService {
  AtsService();

  static const _storageKey = 'cvnova_ats_analyses_v1';

  Future<List<ResumeAnalysis>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ResumeAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<ResumeAnalysis> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<ResumeAnalysis> analyze({
    required List<int> fileBytes,
    required String filename,
    List<String>? targetKeywords,
  }) async {
    // 1. Extract text from PDF using pure Dart pdf engine
    final text = PdfExtractor.extractText(fileBytes);

    // 2. Score text with deterministic ATS algorithm
    final result = AtsScorer.score(text, targetKeywords: targetKeywords);

    // 3. Create persistent analysis record
    final analysis = ResumeAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filename: filename,
      wordCount: result.wordCount,
      score: result.score,
      feedback: result.feedback,
      createdAt: DateTime.now(),
    );

    // 4. Save to local storage (newest first)
    final existing = await _loadAll();
    existing.insert(0, analysis);
    await _saveAll(existing);

    return analysis;
  }

  Future<List<ResumeAnalysisSummary>> history() async {
    final all = await _loadAll();
    return all.map((a) => a.toSummary()).toList();
  }

  /// Returns null rather than throwing when there's no analysis yet —
  /// callers (dashboard) treat "no analysis" as a normal empty state.
  Future<ResumeAnalysis?> latest() async {
    final all = await _loadAll();
    if (all.isEmpty) return null;
    return all.first;
  }

  Future<ResumeAnalysis> getById(String id) async {
    final all = await _loadAll();
    final found = all.where((a) => a.id == id).firstOrNull;
    if (found == null) {
      throw Exception('Analysis not found');
    }
    return found;
  }
}
