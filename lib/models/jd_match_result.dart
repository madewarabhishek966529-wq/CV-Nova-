class JdMatchResult {
  const JdMatchResult({
    required this.matchScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.jobTitle,
    required this.companyName,
    required this.recommendations,
    required this.analyzedAt,
  });

  final int matchScore; // 0 - 100
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final String jobTitle;
  final String companyName;
  final List<String> recommendations;
  final DateTime analyzedAt;

  factory JdMatchResult.fromJson(Map<String, dynamic> json) => JdMatchResult(
        matchScore: json['match_score'] as int? ?? 0,
        matchedSkills: List<String>.from(json['matched_skills'] as List? ?? []),
        missingSkills: List<String>.from(json['missing_skills'] as List? ?? []),
        jobTitle: json['job_title'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        recommendations: List<String>.from(json['recommendations'] as List? ?? []),
        analyzedAt: DateTime.parse(json['analyzed_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'match_score': matchScore,
        'matched_skills': matchedSkills,
        'missing_skills': missingSkills,
        'job_title': jobTitle,
        'company_name': companyName,
        'recommendations': recommendations,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}
