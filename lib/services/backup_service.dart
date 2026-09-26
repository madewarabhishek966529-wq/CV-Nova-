import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  BackupService._();

  static const _resumesKey = 'cvnova_resumes_v1';
  static const _atsKey = 'cvnova_ats_analyses_v1';

  /// Generates a full portable JSON backup of all user resumes and ATS history.
  static Future<String> generateBackupJson() async {
    final prefs = await SharedPreferences.getInstance();
    final resumesRaw = prefs.getString(_resumesKey);
    final atsRaw = prefs.getString(_atsKey);

    final data = {
      'app': 'CVNova',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'resumes': resumesRaw != null ? jsonDecode(resumesRaw) : [],
      'ats_analyses': atsRaw != null ? jsonDecode(atsRaw) : [],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restores data from [backupJsonString]. Returns count of restored items.
  static Future<Map<String, int>> restoreFromJson(String backupJsonString) async {
    final Map<String, dynamic> data = jsonDecode(backupJsonString);
    final prefs = await SharedPreferences.getInstance();

    int resumesCount = 0;
    int atsCount = 0;

    if (data.containsKey('resumes') && data['resumes'] is List) {
      final resumesList = data['resumes'] as List;
      await prefs.setString(_resumesKey, jsonEncode(resumesList));
      resumesCount = resumesList.length;
    }

    if (data.containsKey('ats_analyses') && data['ats_analyses'] is List) {
      final atsList = data['ats_analyses'] as List;
      await prefs.setString(_atsKey, jsonEncode(atsList));
      atsCount = atsList.length;
    }

    return {
      'resumes': resumesCount,
      'ats': atsCount,
    };
  }
}
