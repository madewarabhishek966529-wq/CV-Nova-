import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/resume.dart';

class ResumeService {
  ResumeService();

  static const _storageKey = 'cvnova_resumes_v1';

  Future<List<Resume>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      // First launch: initialize with a realistic starter resume
      final initial = _createStarterResume();
      await _saveAll([initial]);
      return [initial];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Resume.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<Resume> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  Future<List<ResumeSummary>> list() async {
    final all = await _loadAll();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all.map((r) => r.toSummary()).toList();
  }

  Future<Resume> get(String id) async {
    final all = await _loadAll();
    final found = all.where((r) => r.id == id).firstOrNull;
    if (found == null) {
      throw Exception('Resume not found');
    }
    return found;
  }

  Future<Resume> create({required String title, required String template}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final resume = Resume(
      id: id,
      userId: 'local_user',
      title: title.isEmpty ? 'Untitled Resume' : title,
      template: template.isEmpty ? 'modern' : template,
      updatedAt: DateTime.now(),
      isPrimary: false,
    );

    final all = await _loadAll();
    all.insert(0, resume);
    await _saveAll(all);
    return resume;
  }

  Future<Resume> update(Resume resume) async {
    final all = await _loadAll();
    final index = all.indexWhere((r) => r.id == resume.id);
    final updated = resume.copyWith();
    final updatedWithTime = Resume(
      id: updated.id,
      userId: updated.userId,
      title: updated.title,
      template: updated.template,
      themeColor: updated.themeColor,
      font: updated.font,
      isPrimary: updated.isPrimary,
      photoUrl: updated.photoUrl,
      headline: updated.headline,
      professionalSummary: updated.professionalSummary,
      personalInfo: updated.personalInfo,
      experience: updated.experience,
      projects: updated.projects,
      education: updated.education,
      certifications: updated.certifications,
      achievements: updated.achievements,
      skills: updated.skills,
      languages: updated.languages,
      interests: updated.interests,
      references: updated.references,
      links: updated.links,
      customSections: updated.customSections,
      sectionOrder: updated.sectionOrder,
      hiddenSections: updated.hiddenSections,
      updatedAt: DateTime.now(),
    );

    if (index >= 0) {
      all[index] = updatedWithTime;
    } else {
      all.insert(0, updatedWithTime);
    }
    await _saveAll(all);
    return updatedWithTime;
  }

  Future<void> delete(String id) async {
    final all = await _loadAll();
    all.removeWhere((r) => r.id == id);
    await _saveAll(all);
  }

  Future<Resume> duplicate(String id) async {
    final original = await get(id);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final copy = Resume(
      id: newId,
      userId: original.userId,
      title: '${original.title} (Copy)',
      template: original.template,
      themeColor: original.themeColor,
      font: original.font,
      isPrimary: false,
      photoUrl: original.photoUrl,
      headline: original.headline,
      professionalSummary: original.professionalSummary,
      personalInfo: original.personalInfo,
      experience: original.experience,
      projects: original.projects,
      education: original.education,
      certifications: original.certifications,
      achievements: original.achievements,
      skills: List.from(original.skills),
      languages: original.languages,
      interests: List.from(original.interests),
      references: original.references,
      links: original.links,
      customSections: original.customSections,
      sectionOrder: List.from(original.sectionOrder),
      hiddenSections: List.from(original.hiddenSections),
      updatedAt: DateTime.now(),
    );

    final all = await _loadAll();
    all.insert(0, copy);
    await _saveAll(all);
    return copy;
  }

  static Resume _createStarterResume() {
    final now = DateTime.now();
    return Resume(
      id: 'starter_1',
      userId: 'local_user',
      title: 'Full Stack Engineer Resume',
      template: 'modern',
      themeColor: '#4A3AFF',
      font: 'inter',
      isPrimary: true,
      headline: 'Senior Full Stack Software Engineer',
      professionalSummary:
          'Passionate software engineer with 5+ years of experience architecting high-scale web and mobile applications using Flutter, React, and Python. Proven track record in improving system reliability and performance.',
      personalInfo: PersonalInfo(
        fullName: 'Alex Morgan',
        email: 'alex.morgan@example.com',
        phone: '+1 (555) 234-5678',
        location: 'San Francisco, CA',
        website: 'https://alexmorgan.dev',
      ),
      experience: [
        ExperienceItem(
          id: 'exp_1',
          company: 'NovaTech Solutions',
          role: 'Lead Mobile & Full Stack Engineer',
          startDate: '2022',
          endDate: 'Present',
          isCurrent: true,
          location: 'San Francisco, CA',
          bullets: [
            'Architected cross-platform mobile apps using Flutter, increasing user engagement by 45%.',
            'Optimized REST & GraphQL backend services, reducing API response times by 30%.',
            'Mentored 6 junior engineers and instituted automated CI/CD test pipelines.',
          ],
        ),
        ExperienceItem(
          id: 'exp_2',
          company: 'Vertex Digital Labs',
          role: 'Software Engineer',
          startDate: '2020',
          endDate: '2022',
          isCurrent: false,
          location: 'Seattle, WA',
          bullets: [
            'Built real-time dashboard analytics with React, TypeScript, and WebSockets.',
            'Collaborated with product designers to implement pixel-perfect user interfaces.',
          ],
        ),
      ],
      education: [
        EducationItem(
          id: 'edu_1',
          institution: 'University of California, Berkeley',
          degree: 'Bachelor of Science in Computer Science',
          startDate: '2016',
          endDate: '2020',
          grade: '3.8 GPA',
        ),
      ],
      skills: [
        'Flutter & Dart',
        'TypeScript / React',
        'Python',
        'REST APIs',
        'Git & CI/CD',
        'Cloud (AWS/GCP)',
        'PostgreSQL & SQLite',
        'System Architecture',
      ],
      projects: [
        ProjectItem(
          id: 'proj_1',
          name: 'CVNova App',
          description: 'Modern offline-first resume builder and ATS analyzer with real-time scoring.',
          techStack: ['Flutter', 'Dart', 'Riverpod'],
          link: 'https://github.com',
          bullets: [
            'Engineered deterministic ATS scoring engine analyzing keyword density and formatting.',
            'Implemented instant live resume preview with dynamic themes and reordering.',
          ],
        ),
      ],
      certifications: [
        CertificationItem(
          id: 'cert_1',
          name: 'AWS Certified Solutions Architect',
          issuer: 'Amazon Web Services',
          issueDate: '2023',
        ),
      ],
      updatedAt: now,
    );
  }
}
