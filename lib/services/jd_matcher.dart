import '../models/jd_match_result.dart';
import '../models/resume.dart';

class JdMatcher {
  static const List<String> _commonTechSkills = [
    // Mobile & Frontend
    'flutter', 'dart', 'react', 'react native', 'javascript', 'typescript',
    'swift', 'kotlin', 'android', 'ios', 'html', 'css', 'tailwind', 'vue',
    'angular', 'next.js', 'redux', 'riverpod', 'bloc', 'state management',

    // Backend & Languages
    'python', 'java', 'golang', 'c++', 'c#', '.net', 'rust', 'node.js',
    'fastapi', 'django', 'spring boot', 'express', 'rest api', 'graphql',
    'microservices', 'clean architecture', 'system design',

    // Cloud & DevOps
    'aws', 'azure', 'gcp', 'google cloud', 'docker', 'kubernetes', 'ci/cd',
    'git', 'github', 'gitlab', 'jenkins', 'terraform', 'linux', 'cloud',

    // Data & Databases
    'sql', 'postgresql', 'mysql', 'mongodb', 'redis', 'sqlite', 'firebase',
    'supabase', 'elasticsearch', 'data analysis', 'machine learning', 'ai',

    // Process & Soft Skills
    'agile', 'scrum', 'testing', 'unit testing', 'automated testing',
    'leadership', 'mentorship', 'communication', 'problem solving',
    'teamwork', 'cross-functional', 'project management', 'performance optimization',
  ];

  static JdMatchResult match({
    required String jobDescription,
    required Resume resume,
    String jobTitle = '',
    String companyName = '',
  }) {
    final lowerJd = jobDescription.toLowerCase();

    // 1. Gather all resume text
    final resumeBuffer = StringBuffer();
    resumeBuffer.writeln(resume.headline ?? '');
    resumeBuffer.writeln(resume.professionalSummary ?? '');
    for (final skill in resume.skills) {
      resumeBuffer.writeln(skill);
    }
    for (final exp in resume.experience) {
      resumeBuffer.writeln('${exp.role} ${exp.company}');
      for (final bullet in exp.bullets) {
        resumeBuffer.writeln(bullet);
      }
    }
    for (final proj in resume.projects) {
      resumeBuffer.writeln('${proj.name} ${proj.description} ${proj.techStack.join(' ')}');
      for (final bullet in proj.bullets) {
        resumeBuffer.writeln(bullet);
      }
    }
    for (final edu in resume.education) {
      resumeBuffer.writeln('${edu.institution} ${edu.degree} ${edu.fieldOfStudy}');
    }

    final lowerResumeText = resumeBuffer.toString().toLowerCase();

    // 2. Identify skills mentioned in the Job Description
    final jdTargetSkills = <String>{};
    for (final skill in _commonTechSkills) {
      final pattern = RegExp('\\b${RegExp.escape(skill)}\\b');
      if (pattern.hasMatch(lowerJd)) {
        jdTargetSkills.add(skill);
      }
    }

    // Dynamic extraction: if job description mentions custom terms (e.g. extracted words)
    final words = lowerJd.split(RegExp(r'[\s,;/]+')).where((w) => w.length >= 4).toSet();
    for (final word in words) {
      if (_commonTechSkills.contains(word)) {
        jdTargetSkills.add(word);
      }
    }

    if (jdTargetSkills.isEmpty) {
      // Fallback: search common keywords
      for (final skill in _commonTechSkills.take(12)) {
        if (lowerJd.contains(skill)) {
          jdTargetSkills.add(skill);
        }
      }
    }

    // 3. Compare with Resume
    final matched = <String>[];
    final missing = <String>[];

    for (final skill in jdTargetSkills) {
      final pattern = RegExp('\\b${RegExp.escape(skill)}\\b');
      if (pattern.hasMatch(lowerResumeText)) {
        matched.add(_capitalize(skill));
      } else {
        missing.add(_capitalize(skill));
      }
    }

    final totalTarget = jdTargetSkills.length;
    final int score;
    if (totalTarget == 0) {
      score = 75; // Neutral
    } else {
      score = ((matched.length / totalTarget) * 100).round().clamp(0, 100);
    }

    // 4. Generate Targeted Recommendations
    final recommendations = <String>[];
    if (missing.isNotEmpty) {
      final topMissing = missing.take(4).join(', ');
      recommendations.add(
        'Add "$topMissing" to your Skills list or weave into relevant project bullet points.',
      );
    }

    if (score < 60) {
      recommendations.add(
        'Your resume has a low keyword match with this job posting. Tailor your professional summary to reflect the job requirements.',
      );
    } else if (score < 80) {
      recommendations.add(
        'Good baseline match! Incorporate 2-3 more of the missing skills to reach the 80%+ ATS threshold.',
      );
    } else {
      recommendations.add(
        'Excellent match! Your profile strongly aligns with the core requirements of this role.',
      );
    }

    if (resume.experience.isEmpty) {
      recommendations.add('Add work experience entries highlighting quantified achievements.');
    }

    return JdMatchResult(
      matchScore: score,
      matchedSkills: matched,
      missingSkills: missing,
      jobTitle: jobTitle.trim(),
      companyName: companyName.trim(),
      recommendations: recommendations,
      analyzedAt: DateTime.now(),
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.toLowerCase() == 'ci/cd' || word.toLowerCase() == 'api' || word.toLowerCase() == 'sql' || word.toLowerCase() == 'aws' || word.toLowerCase() == 'gcp' || word.toLowerCase() == 'ui/ux') {
        return word.toUpperCase();
      }
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
