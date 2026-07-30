import '../models/resume.dart';
import 'api_client.dart';

class ResumeService {
  ResumeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ResumeSummary>> list(String token) async {
    final json = await _api.getJsonList('/resumes', token: token);
    return json.map((e) => ResumeSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Resume> get(String id, String token) async {
    final json = await _api.getJson('/resumes/$id', token: token);
    return Resume.fromJson(json);
  }

  Future<Resume> create({
    required String title,
    required String template,
    required String token,
  }) async {
    final json = await _api.postJson(
      '/resumes',
      body: {'title': title, 'template': template},
      token: token,
    );
    return Resume.fromJson(json);
  }

  Future<Resume> update(Resume resume, String token) async {
    final json = await _api.putJson(
      '/resumes/${resume.id}',
      body: resume.toUpdateJson(),
      token: token,
    );
    return Resume.fromJson(json);
  }

  Future<void> delete(String id, String token) async {
    await _api.delete('/resumes/$id', token: token);
  }

  Future<Resume> duplicate(String id, String token) async {
    final json = await _api.postJson('/resumes/$id/duplicate', token: token);
    return Resume.fromJson(json);
  }
}
