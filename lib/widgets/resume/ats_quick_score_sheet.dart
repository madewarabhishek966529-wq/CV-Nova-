import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resume.dart';
import '../../models/resume_analysis.dart';
import '../../providers/ats_provider.dart';
import '../../services/ats_scorer.dart';
import '../../services/ats_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../common/glass_card.dart';
import '../common/score_ring.dart';

class AtsQuickScoreSheet extends ConsumerStatefulWidget {
  const AtsQuickScoreSheet({super.key, required this.resume});
  final Resume resume;

  static Future<void> show(BuildContext context, Resume resume) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AtsQuickScoreSheet(resume: resume),
    );
  }

  @override
  ConsumerState<AtsQuickScoreSheet> createState() => _AtsQuickScoreSheetState();
}

class _AtsQuickScoreSheetState extends ConsumerState<AtsQuickScoreSheet> {
  ResumeAnalysis? _analysis;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _computeScore();
  }

  Future<void> _computeScore() async {
    final buffer = StringBuffer();
    final r = widget.resume;
    buffer.writeln(r.personalInfo.fullName);
    buffer.writeln('${r.personalInfo.email} ${r.personalInfo.phone}');
    buffer.writeln('Summary: ${r.professionalSummary ?? ""}');
    buffer.writeln('Experience:');
    for (final exp in r.experience) {
      buffer.writeln('${exp.role} at ${exp.company} (${exp.startDate} - ${exp.endDate})');
      for (final b in exp.bullets) {
        buffer.writeln('• $b');
      }
    }
    buffer.writeln('Skills: ${r.skills.join(", ")}');
    buffer.writeln('Education:');
    for (final edu in r.education) {
      buffer.writeln('${edu.degree} ${edu.fieldOfStudy} ${edu.institution}');
    }

    final text = buffer.toString();
    final result = AtsScorer.score(text);

    final analysis = ResumeAnalysis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filename: '${r.title} (Live)',
      wordCount: result.wordCount,
      score: result.score,
      feedback: result.feedback,
      createdAt: DateTime.now(),
    );

    // Save to local storage asynchronously
    await AtsService().analyze(
      fileBytes: [1], // stub bytes, text scored directly
      filename: '${r.title}.pdf',
    ).catchError((_) => analysis);

    if (mounted) {
      setState(() {
        _analysis = analysis;
        _loading = false;
      });
      ref.read(atsProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = _analysis;

    return RepaintBoundary(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1220) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, -6)),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0x38FFFFFF) : const Color(0x28000000),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Instant ATS Check',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading || a == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Score Header
                        GlassCard(
                          gradient: AppGradients.glassCard(Theme.of(context).brightness),
                          child: Row(
                            children: [
                              ScoreRing(value: a.score.overall / 100.0, size: 84),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall ATS Score',
                                      style: TextStyle(
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      a.score.overall >= 75
                                          ? 'Ready for submission! 🎉'
                                          : (a.score.overall >= 50
                                              ? 'Good, but needs polish ⚡'
                                              : 'Needs critical fixes ⚠️'),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${a.wordCount} words detected across sections.',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dimension Pills
                        Row(
                          children: [
                            Expanded(child: _ScorePill(label: 'Formatting', score: a.score.formatting, color: AppColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(child: _ScorePill(label: 'Impact', score: a.score.impact, color: AppColors.secondary)),
                            const SizedBox(width: 10),
                            Expanded(child: _ScorePill(label: 'Keywords', score: a.score.keywords, color: AppColors.amber)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Strengths
                        if (a.feedback.strengths.isNotEmpty) ...[
                          Text('Strengths', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.mint)),
                          const SizedBox(height: 8),
                          ...a.feedback.strengths.map((s) => _FeedbackItem(text: s, icon: Icons.check_circle_rounded, color: AppColors.mint)),
                          const SizedBox(height: 16),
                        ],

                        // Suggestions / Weaknesses
                        if (a.feedback.suggestions.isNotEmpty || a.feedback.weaknesses.isNotEmpty) ...[
                          Text('Recommendations to Boost Score', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.amber)),
                          const SizedBox(height: 8),
                          ...a.feedback.suggestions.map((s) => _FeedbackItem(text: s, icon: Icons.arrow_circle_right_rounded, color: AppColors.amber)),
                          ...a.feedback.weaknesses.map((w) => _FeedbackItem(text: w, icon: Icons.info_outline_rounded, color: AppColors.coral)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.score, required this.color});
  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$score%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  const _FeedbackItem({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }
}
