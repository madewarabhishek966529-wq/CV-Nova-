class ScoreBreakdown {
  const ScoreBreakdown({
    required this.overall,
    required this.formatting,
    required this.keywords,
    required this.impact,
  });

  final int overall;
  final int formatting;
  final int keywords;
  final int impact;

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) => ScoreBreakdown(
        overall: json['overall'] as int,
        formatting: json['formatting'] as int,
        keywords: json['keywords'] as int,
        impact: json['impact'] as int,
      );
}

class AnalysisFeedback {
  const AnalysisFeedback({
    required this.strengths,
    required this.weaknesses,
    required this.missingKeywords,
    required this.suggestions,
  });

  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missingKeywords;
  final List<String> suggestions;

  factory AnalysisFeedback.fromJson(Map<String, dynamic> json) => AnalysisFeedback(
        strengths: List<String>.from(json['strengths'] as List? ?? const []),
        weaknesses: List<String>.from(json['weaknesses'] as List? ?? const []),
        missingKeywords: List<String>.from(json['missing_keywords'] as List? ?? const []),
        suggestions: List<String>.from(json['suggestions'] as List? ?? const []),
      );
}

/// Lightweight shape for history lists — mirrors the backend's
/// ResumeAnalysisSummary (no feedback payload).
class ResumeAnalysisSummary {
  const ResumeAnalysisSummary({
    required this.id,
    required this.filename,
    required this.wordCount,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final String filename;
  final int wordCount;
  final ScoreBreakdown score;
  final DateTime createdAt;

  factory ResumeAnalysisSummary.fromJson(Map<String, dynamic> json) => ResumeAnalysisSummary(
        id: json['id'] as String,
        filename: json['filename'] as String,
        wordCount: json['word_count'] as int,
        score: ScoreBreakdown.fromJson(json['score'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class ResumeAnalysis {
  const ResumeAnalysis({
    required this.id,
    required this.filename,
    required this.wordCount,
    required this.score,
    required this.feedback,
    required this.createdAt,
  });

  final String id;
  final String filename;
  final int wordCount;
  final ScoreBreakdown score;
  final AnalysisFeedback feedback;
  final DateTime createdAt;

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) => ResumeAnalysis(
        id: json['id'] as String,
        filename: json['filename'] as String,
        wordCount: json['word_count'] as int,
        score: ScoreBreakdown.fromJson(json['score'] as Map<String, dynamic>),
        feedback: AnalysisFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
