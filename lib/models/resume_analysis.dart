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

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'formatting': formatting,
        'keywords': keywords,
        'impact': impact,
      };
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

  Map<String, dynamic> toJson() => {
        'strengths': strengths,
        'weaknesses': weaknesses,
        'missing_keywords': missingKeywords,
        'suggestions': suggestions,
      };
}

/// Lightweight shape for history lists — mirrors ResumeAnalysisSummary.
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'word_count': wordCount,
        'score': score.toJson(),
        'created_at': createdAt.toIso8601String(),
      };
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'word_count': wordCount,
        'score': score.toJson(),
        'feedback': feedback.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  ResumeAnalysisSummary toSummary() => ResumeAnalysisSummary(
        id: id,
        filename: filename,
        wordCount: wordCount,
        score: score,
        createdAt: createdAt,
      );
}
