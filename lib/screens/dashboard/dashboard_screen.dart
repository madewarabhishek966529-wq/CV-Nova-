import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/ats_provider.dart';
import '../../providers/resume_list_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../services/pdf_export_service.dart';
import '../../services/resume_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/backup_restore_dialog.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/score_ring.dart';
import '../../widgets/resume/ats_quick_score_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(atsProvider.notifier).load();
      ref.read(resumeListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final ats = ref.watch(atsProvider);
    final resumeState = ref.watch(resumeListProvider);
    final resumes = resumeState.resumes;

    final primaryResume = resumes.where((r) => r.isPrimary).firstOrNull ??
        (resumes.isNotEmpty ? resumes.first : null);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const AppLogo(size: 34, showText: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup_outlined),
            tooltip: 'Backup & Restore',
            onPressed: () => BackupRestoreDialog.show(context),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting & Tagline
                  Text(
                    'Career Command Center',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.primary : AppColors.primaryDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Build, Match & Optimize',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // 2x2 Vibrant Feature Grid
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureTile(
                          title: 'My Resumes',
                          subtitle: '${resumes.length} saved',
                          icon: Icons.description_rounded,
                          gradient: AppGradients.primary,
                          onTap: () => context.push(RouteNames.resumeList),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _FeatureTile(
                          title: 'JD Matcher',
                          subtitle: 'Scan Job Fit',
                          icon: Icons.troubleshoot_rounded,
                          gradient: AppGradients.cyan,
                          onTap: () => context.push(RouteNames.jdMatcher),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureTile(
                          title: 'ATS Scanner',
                          subtitle: 'Upload & Score',
                          icon: Icons.insights_rounded,
                          gradient: AppGradients.amber,
                          onTap: () => context.push(RouteNames.atsAnalyzer),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _FeatureTile(
                          title: 'Backup & Sync',
                          subtitle: 'Export JSON',
                          icon: Icons.sync_rounded,
                          gradient: AppGradients.mint,
                          onTap: () => BackupRestoreDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ATS Score Overview Card
                  RepaintBoundary(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => context.push(RouteNames.atsAnalyzer),
                      child: GlassCard(
                        child: _AtsScoreCardContent(ats: ats),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Primary Resume Spotlight Card
                  if (primaryResume != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Resume',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RouteNames.resumeList),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _PrimaryResumeCard(summary: primaryResume),
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

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (gradient is LinearGradient ? gradient.colors.first : Colors.black)
                      .withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryResumeCard extends ConsumerWidget {
  const _PrimaryResumeCard({required this.summary});
  final dynamic summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.article_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.headline ?? 'Ready to export & match',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Primary',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionBtn(
                icon: Icons.visibility_outlined,
                label: 'Preview',
                onTap: () => context.push('${RouteNames.resumePreview}/${summary.id}'),
              ),
              _ActionBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () => context.push('${RouteNames.resumeEditor}/${summary.id}'),
              ),
              _ActionBtn(
                icon: Icons.bolt_rounded,
                label: '1-Tap ATS',
                color: AppColors.amber,
                onTap: () async {
                  final resume = await ResumeService().get(summary.id);
                  if (context.mounted) {
                    AtsQuickScoreSheet.show(context, resume);
                  }
                },
              ),
              _ActionBtn(
                icon: Icons.share_rounded,
                label: 'Share PDF',
                color: AppColors.cyan,
                onTap: () async {
                  final resume = await ResumeService().get(summary.id);
                  await PdfExportService.exportAndShare(resume);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtsScoreCardContent extends StatelessWidget {
  const _AtsScoreCardContent({required this.ats});
  final dynamic ats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ats.loadStatus == AtsLoadStatus.loading && ats.latest == null) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final latest = ats.latest;
    if (latest == null) {
      return Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.amber,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATS Resume Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upload a resume PDF to calculate your benchmark score.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ScoreRing(value: latest.score.overall / 100.0, size: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest ATS Score',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latest.score.overall >= 75
                        ? 'High Competitiveness 🚀'
                        : (latest.score.overall >= 50
                            ? 'Moderate Match ⚡'
                            : 'Needs Polish ⚠️'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    latest.filename,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _MiniScorePill(label: 'Format', val: '${latest.score.formatting}%', color: AppColors.primary),
            const SizedBox(width: 8),
            _MiniScorePill(label: 'Impact', val: '${latest.score.impact}%', color: AppColors.secondary),
            const SizedBox(width: 8),
            _MiniScorePill(label: 'Keywords', val: '${latest.score.keywords}%', color: AppColors.amber),
          ],
        ),
      ],
    );
  }
}

class _MiniScorePill extends StatelessWidget {
  const _MiniScorePill({required this.label, required this.val, required this.color});
  final String label;
  final String val;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
