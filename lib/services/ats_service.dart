import '../models/resume_analysis.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class AtsService {
  AtsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<ResumeAnalysis> analyze({
    required List<int> fileBytes,
    required String filename,
    List<String>? targetKeywords,
  }) async {
    final json = await _api.postMultipart(
      '/ats/analyze',
      fileFieldName: 'file',
      fileBytes: fileBytes,
      filename: filename,
      fields: {
        if (targetKeywords != null && targetKeywords.isNotEmpty)
          'target_keywords': targetKeywords.join(','),
      },
    );
    return ResumeAnalysis.fromJson(json);
  }

  Future<List<ResumeAnalysisSummary>> history() async {
    final json = await _api.getJsonList('/ats/analyses');
    return json.map((e) => ResumeAnalysisSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Returns null rather than throwing when there's no analysis yet (404) —
  /// callers (dashboard) treat "no analysis" as a normal empty state.
  Future<ResumeAnalysis?> latest() async {
    try {
      final json = await _api.getJson('/ats/analyses/latest');
      return ResumeAnalysis.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<ResumeAnalysis> getById(String id) async {
    final json = await _api.getJson('/ats/analyses/$id');
    return ResumeAnalysis.fromJson(json);
  }
}
