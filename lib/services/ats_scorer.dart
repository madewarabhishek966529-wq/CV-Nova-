import '../models/resume_analysis.dart';

class AtsScorerResult {
  const AtsScorerResult({
    required this.score,
    required this.feedback,
    required this.wordCount,
  });

  final ScoreBreakdown score;
  final AnalysisFeedback feedback;
  final int wordCount;
}

class AtsScorer {
  static const List<String> _sectionHeaders = [
    'experience',
    'education',
    'skills',
    'projects',
    'summary',
    'certifications',
    'achievements',
  ];

  static const Set<String> _actionVerbs = {
    'led', 'built', 'developed', 'designed', 'implemented', 'managed',
    'created', 'improved', 'increased', 'reduced', 'launched', 'architected',
    'optimized', 'automated', 'delivered', 'spearheaded', 'coordinated',
    'analyzed', 'established', 'mentored', 'streamlined', 'drove',
    'engineered', 'executed', 'founded', 'generated', 'achieved',
    'collaborated', 'resolved', 'trained', 'negotiated', 'authored',
    'deployed', 'scaled', 'migrated', 'refactored', 'shipped',
  };

  static const List<String> _genericKeywordBank = [
    'python', 'javascript', 'typescript', 'java', 'sql', 'react', 'flutter',
    'aws', 'azure', 'docker', 'kubernetes', 'git', 'api', 'rest', 'agile',
    'scrum', 'ci/cd', 'testing', 'leadership', 'communication',
    'problem-solving', 'teamwork', 'project management', 'data analysis',
    'machine learning', 'cloud', 'database', 'cross-functional',
  ];

  static final RegExp _emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final RegExp _phoneRegex = RegExp(r'(\+?\d[\d\s().-]{8,}\d)');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _wordRegex = RegExp(r"[A-Za-z']+");

  static List<String> _bulletLikeLines(String text) {
    final lines = text.split('\n').map((ln) => ln.trim()).toList();
    final bullets = lines.where((ln) =>
        ln.startsWith('•') ||
        ln.startsWith('-') ||
        ln.startsWith('*') ||
        ln.startsWith('◦') ||
        ln.startsWith('▪')).toList();
    if (bullets.isNotEmpty) {
      return bullets;
    }
    // Fallback for PDFs that drop bullet glyphs:
    return lines
        .where((ln) => ln.length >= 25 && ln.length <= 200 && !ln.endsWith(':'))
        .toList();
  }

  static AtsScorerResult score(String text, {List<String>? targetKeywords}) {
    final words = _wordRegex.allMatches(text).map((m) => m.group(0)!).toList();
    final wordCount = words.length;
    final lowerText = text.toLowerCase();

    final strengths = <String>[];
    final weaknesses = <String>[];
    final suggestions = <String>[];

    // --- Formatting: length + section headers + contact info ---
    const lo = 400;
    const hi = 1100;
    const minViableWords = 120;
    int lengthScore;

    if (wordCount < minViableWords) {
      lengthScore = 20;
      weaknesses.add('Resume is very short ($wordCount words)');
      suggestions.add(
        'Add more detail to your experience and skills sections — most resumes read as too thin below ~120 words.',
      );
    } else if (wordCount < lo) {
      lengthScore = 65;
      suggestions.add('Consider expanding on your experience bullets a bit further.');
    } else if (wordCount <= hi) {
      lengthScore = 100;
      strengths.add('Resume length is in a strong range ($wordCount words)');
    } else {
      lengthScore = 70;
      suggestions.add(
        'Resume is on the long side ($wordCount words) — consider trimming to the most relevant content.',
      );
    }

    final foundHeaders = _sectionHeaders.where((h) => lowerText.contains(h)).toList();
    final headerScore = ((100 * foundHeaders.length) / _sectionHeaders.length).round();

    if (headerScore >= 70) {
      strengths.add('Uses clear, standard section headers');
    } else {
      final missing = _sectionHeaders.where((h) => !foundHeaders.contains(h)).toList();
      weaknesses.add('Missing some standard section headers');
      suggestions.add('Add clearly labeled sections for: ${missing.take(4).join(', ')}');
    }

    final hasEmail = _emailRegex.hasMatch(text);
    final hasPhone = _phoneRegex.hasMatch(text);
    final contactScore = (hasEmail && hasPhone) ? 100 : ((hasEmail || hasPhone) ? 50 : 0);

    if (contactScore == 100) {
      strengths.add('Contact information (email and phone) is present');
    } else {
      weaknesses.add('Contact information looks incomplete');
      suggestions.add('Make sure both an email and a phone number appear near the top.');
    }

    final formatting = (0.4 * lengthScore + 0.35 * headerScore + 0.25 * contactScore).round();

    // --- Impact: action verbs + quantified results in bullets ---
    final bullets = _bulletLikeLines(text);
    int actionScore;
    int quantifiedScore;

    if (bullets.isNotEmpty) {
      final actionHits = bullets.where((b) {
        final cleaned = b.replaceAll(RegExp(r'^[•\-\*◦▪\s]+'), '');
        final firstWord = cleaned.split(' ').first.toLowerCase().replaceAll(RegExp(r'[.,]'), '');
        return _actionVerbs.contains(firstWord);
      }).length;

      final quantifiedHits = bullets.where((b) => _digitRegex.hasMatch(b)).length;

      actionScore = ((100 * actionHits) / bullets.length).round();
      quantifiedScore = ((100 * quantifiedHits) / bullets.length).round();
    } else {
      actionScore = 0;
      quantifiedScore = 0;
      weaknesses.add("Couldn't detect distinct bullet points");
      suggestions.add('Use bullet points to describe your experience, one accomplishment per line.');
    }

    if (actionScore >= 50) {
      strengths.add('Bullets frequently open with strong action verbs');
    } else {
      weaknesses.add('Few bullets open with a strong action verb');
      suggestions.add(
        "Start bullets with action verbs like 'built', 'led', 'improved', or 'reduced' rather than passive phrasing.",
      );
    }

    if (quantifiedScore >= 40) {
      strengths.add('Several bullets include measurable results');
    } else {
      weaknesses.add('Few bullets include numbers or measurable impact');
      suggestions.add(
        "Quantify results where you can — e.g. 'reduced load time by 30%' instead of 'improved performance'.",
      );
    }

    final impact = (0.5 * actionScore + 0.5 * quantifiedScore).round();

    // --- Keywords: against target list or generic bank ---
    final List<String> bank;
    if (targetKeywords != null && targetKeywords.isNotEmpty) {
      bank = targetKeywords
          .map((k) => k.trim().toLowerCase())
          .where((k) => k.isNotEmpty)
          .toList();
    } else {
      bank = _genericKeywordBank;
    }

    List<String> missingKeywords = [];
    int keywordsScore = 0;

    if (bank.isNotEmpty) {
      final foundKeywords = bank.where((k) => lowerText.contains(k)).toList();
      missingKeywords = bank.where((k) => !foundKeywords.contains(k)).toList();
      keywordsScore = ((100 * foundKeywords.length) / bank.length).round();
    }

    final topMissing = missingKeywords.take(10).toList();
    if (keywordsScore >= 60) {
      strengths.add('Strong keyword coverage against target keywords');
    } else if (bank.isNotEmpty) {
      weaknesses.add('Low keyword coverage against target keywords');
      if (topMissing.isNotEmpty) {
        suggestions.add('Consider working in relevant keywords such as: ${topMissing.take(5).join(', ')}');
      }
    }

    final overall = (0.3 * formatting + 0.3 * keywordsScore + 0.4 * impact).round();

    return AtsScorerResult(
      score: ScoreBreakdown(
        overall: overall,
        formatting: formatting,
        keywords: keywordsScore,
        impact: impact,
      ),
      feedback: AnalysisFeedback(
        strengths: strengths,
        weaknesses: weaknesses,
        missingKeywords: topMissing,
        suggestions: suggestions,
      ),
      wordCount: wordCount,
    );
  }
}
