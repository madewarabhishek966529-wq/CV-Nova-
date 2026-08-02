import '../models/resume.dart';
import 'api_client.dart';

class ResumeService {
  ResumeService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ResumeSummary>> list() async {
    final json = await _api.getJsonList('/resumes');
    return json.map((e) => ResumeSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Resume> get(String id) async {
    final json = await _api.getJson('/resumes/$id');
    return Resume.fromJson(json);
  }

  Future<Resume> create({required String title, required String template}) async {
    final json = await _api.postJson('/resumes', body: {'title': title, 'template': template});
    return Resume.fromJson(json);
  }

  Future<Resume> update(Resume resume) async {
    final json = await _api.putJson('/resumes/${resume.id}', body: resume.toUpdateJson());
    return Resume.fromJson(json);
  }

  Future<void> delete(String id) async {
    await _api.delete('/resumes/$id');
  }

  Future<Resume> duplicate(String id) async {
    final json = await _api.postJson('/resumes/$id/duplicate');
    return Resume.fromJson(json);
  }
}
