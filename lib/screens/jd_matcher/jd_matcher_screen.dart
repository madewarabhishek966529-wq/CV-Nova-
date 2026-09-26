import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resume.dart';
import '../../providers/jd_matcher_provider.dart';
import '../../providers/resume_list_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class JdMatcherScreen extends ConsumerStatefulWidget {
  const JdMatcherScreen({super.key, this.initialResumeId});
  final String? initialResumeId;

  @override
  ConsumerState<JdMatcherScreen> createState() => _JdMatcherScreenState();
}

class _JdMatcherScreenState extends ConsumerState<JdMatcherScreen> {
  final _jdController = TextEditingController();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(resumeListProvider.notifier).load();
      if (widget.initialResumeId != null) {
        ref.read(jdMatcherProvider.notifier).selectResume(widget.initialResumeId!);
      }
    });
  }

  @override
  void dispose() {
    _jdController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _jdController.text = data.text!;
      HapticFeedback.lightImpact();
    }
  }

  void _onMatch(List<ResumeSummary> resumes) {
    final jdState = ref.read(jdMatcherProvider);
    final selectedId = jdState.selectedResumeId ??
        (resumes.isNotEmpty ? resumes.first.id : null);

    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create or select a resume first.')),
      );
      return;
    }

    ref.read(jdMatcherProvider.notifier).matchJobDescription(
          jobDescription: _jdController.text,
          resumeId: selectedId,
          jobTitle: _titleController.text,
          companyName: _companyController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resumeState = ref.watch(resumeListProvider);
    final jdState = ref.watch(jdMatcherProvider);
    final resumes = resumeState.resumes;

    final activeResumeId = jdState.selectedResumeId ??
        (resumes.isNotEmpty ? resumes.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Description Matcher'),
        elevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Match Your Resume with Any Job',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste a job description to calculate your ATS match percentage and see missing keywords to add.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Resume Selector Card
                  if (resumes.isNotEmpty) ...[
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comparing Against:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: activeResumeId,
                                    isDense: true,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                    items: resumes.map((r) {
                                      return DropdownMenuItem<String>(
                                        value: r.id,
                                        child: Text(
                                          r.title,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(jdMatcherProvider.notifier).selectResume(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Job Posting Input Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Job Title (Optional)',
                                  hintText: 'e.g. Senior Flutter Developer',
                                  prefixIcon: Icon(Icons.work_outline_rounded, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _companyController,
                                decoration: const InputDecoration(
                                  labelText: 'Company (Optional)',
                                  hintText: 'e.g. Google',
                                  prefixIcon: Icon(Icons.business_outlined, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Job Description Text',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: _pasteFromClipboard,
                              icon: const Icon(Icons.content_paste_rounded, size: 16),
                              label: const Text('Paste'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _jdController,
                          maxLines: 7,
                          decoration: InputDecoration(
                            hintText: 'Paste the requirements, responsibilities, or entire job post here...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        GradientButton(
                          label: 'Calculate Match Score',
                          icon: Icons.auto_awesome_rounded,
                          loading: jdState.isMatching,
                          gradient: AppGradients.hero,
                          onPressed: () => _onMatch(resumes),
                        ),
                      ],
                    ),
                  ),

                  if (jdState.error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      jdState.error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13),
                    ),
                  ],

                  // Results Section
                  if (jdState.result != null) ...[
                    const SizedBox(height: 24),
                    _JdMatchResultView(result: jdState.result!),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JdMatchResultView extends ConsumerWidget {
  const _JdMatchResultView({required this.result});
  final dynamic result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = result.matchScore as int;
    final matched = result.matchedSkills as List<String>;
    final missing = result.missingSkills as List<String>;
    final recommendations = result.recommendations as List<String>;

    final scoreColor = score >= 75
        ? AppColors.mint
        : (score >= 50 ? AppColors.amber : AppColors.coral);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Score Banner
          GlassCard(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scoreColor.withValues(alpha: 0.18),
                const Color(0xFF101322),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score >= 75
                            ? 'High Alignment! 🚀'
                            : (score >= 50 ? 'Moderate Match ⚡' : 'Needs Optimization ⚠️'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matches ${matched.length} of ${matched.length + missing.length} key technical & role requirements.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Missing Skills (Interactive 1-Tap Add)
          if (missing.isNotEmpty) ...[
            Text(
              'Missing Skills (Tap + to add directly to your resume):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missing.map((skill) {
                return _InteractiveSkillChip(
                  skill: skill,
                  isMissing: true,
                  onAdd: () async {
                    final success = await ref
                        .read(jdMatcherProvider.notifier)
                        .addSkillToResume(skill);
                    if (context.mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added "$skill" to your resume!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Matched Skills
          if (matched.isNotEmpty) ...[
            Text(
              'Matched Skills (${matched.length}):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.mint,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matched.map((skill) {
                return _InteractiveSkillChip(
                  skill: skill,
                  isMissing: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Recommendations
          if (recommendations.isNotEmpty) ...[
            Text(
              'Targeted Optimization Advice:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _InteractiveSkillChip extends StatelessWidget {
  const _InteractiveSkillChip({
    required this.skill,
    required this.isMissing,
    this.onAdd,
  });

  final String skill;
  final bool isMissing;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final color = isMissing ? AppColors.amber : AppColors.mint;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isMissing ? onAdd : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                skill,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (isMissing) ...[
                const SizedBox(width: 6),
                Icon(Icons.add_circle_outline_rounded, size: 16, color: color),
              ] else ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded, size: 16, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
