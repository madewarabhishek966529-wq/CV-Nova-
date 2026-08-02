import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/ats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/score_ring.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(atsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final ats = ref.watch(atsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good to see you.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s where your career stands today.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push(RouteNames.atsAnalyzer),
                child: GlassCard(child: _AtsScoreCardContent(ats: ats)),
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push(RouteNames.resumeList),
                child: GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppColors.indigo, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Resumes', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              'Build, edit, and manage your resumes.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a real ATS score once one exists; otherwise an honest empty-state
/// CTA rather than a placeholder number. Same tap target (the whole card)
/// either way — both lead to the analyzer.
class _AtsScoreCardContent extends StatelessWidget {
  const _AtsScoreCardContent({required this.ats});

  final AtsState ats;

  @override
  Widget build(BuildContext context) {
    if (ats.loadStatus == AtsLoadStatus.loading && ats.latest == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    final analysis = ats.latest;
    if (analysis == null) {
      return Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AppColors.indigo, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ATS Resume Checker', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Upload a resume PDF to see your ATS score.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      );
    }

    return Row(
      children: [
        ScoreRing(value: analysis.score.overall / 100, size: 76),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ATS Score', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                analysis.filename,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Tap to see the full breakdown',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}
