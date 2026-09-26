import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cvnova/models/resume.dart';
import 'package:cvnova/services/jd_matcher.dart';
import 'package:cvnova/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('JdMatcher Tests', () {
    test('accurately extracts matching skills and identifies missing gaps', () {
      final resume = Resume(
        id: 'test-resume-1',
        userId: 'user-123',
        title: 'Senior Mobile Dev',
        updatedAt: DateTime.now(),
        professionalSummary: 'Expert Flutter and Dart developer with expertise in Firebase and Git.',
        personalInfo: PersonalInfo(
          fullName: 'Jane Doe',
          email: 'jane@example.com',
        ),
        skills: ['Flutter', 'Dart', 'Firebase', 'Git', 'REST APIs'],
      );

      const jobDescription = '''
We are looking for a Senior Flutter Developer.
Requirements:
- Flutter and Dart experience
- Experience with Firebase and AWS cloud
- Strong knowledge of Docker and CI/CD pipelines
- Git version control
- Bachelor degree in Computer Science
''';

      final result = JdMatcher.match(resume: resume, jobDescription: jobDescription);

      expect(result.matchScore, greaterThan(0));
      expect(result.matchedSkills, contains('Flutter'));
      expect(result.matchedSkills, contains('Dart'));
      expect(result.matchedSkills, contains('Firebase'));
      expect(result.missingSkills, contains('Docker'));
      expect(result.missingSkills, contains('AWS'));
      expect(result.recommendations, isNotEmpty);
    });
  });

  group('BackupService Tests', () {
    test('creates export and restores resumes successfully', () async {
      final resume = Resume(
        id: 'res-999',
        userId: 'user-123',
        title: 'Cloud Architect Resume',
        updatedAt: DateTime.now(),
        personalInfo: PersonalInfo(fullName: 'Alex River', email: 'alex@example.com'),
        skills: ['AWS', 'Kubernetes'],
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cvnova_resumes_v1', jsonEncode([resume.toJson()]));

      final backupJson = await BackupService.generateBackupJson();
      expect(backupJson, contains('res-999'));
      expect(backupJson, contains('Cloud Architect Resume'));

      // Clear prefs
      await prefs.clear();

      // Restore
      final restoreResult = await BackupService.restoreFromJson(backupJson);
      expect(restoreResult['resumes'], 1);

      final stored = prefs.getString('cvnova_resumes_v1');
      expect(stored, contains('Cloud Architect Resume'));
    });
  });
}
