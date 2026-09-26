import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/resume.dart';
import '../../providers/resume_list_provider.dart';
import '../../routes/route_names.dart';
import '../../services/pdf_export_service.dart';
import '../../services/resume_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/resume/ats_quick_score_sheet.dart';

class ResumeListScreen extends ConsumerStatefulWidget {
  const ResumeListScreen({super.key});

  @override
  ConsumerState<ResumeListScreen> createState() => _ResumeListScreenState();
}

class _ResumeListScreenState extends ConsumerState<ResumeListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(resumeListProvider.notifier).load());
  }

  Future<void> _createResume() async {
    final controller = TextEditingController(text: 'Untitled Resume');
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Name your resume'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Software Engineer — Google'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    final resume = await ref.read(resumeListProvider.notifier).create(title: title);
    if (resume != null && mounted) {
      context.push('${RouteNames.resumeEditor}/${resume.id}');
    }
  }

  Future<void> _confirmDelete(ResumeSummary resume) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this resume?'),
        content: Text('"${resume.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(resumeListProvider.notifier).delete(resume.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createResume,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New resume'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(resumeListProvider.notifier).load(),
          child: state.loading && state.resumes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.resumes.isEmpty
                  ? _EmptyState(onCreate: _createResume)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: state.resumes.length,
                      itemBuilder: (context, index) {
                        final r = state.resumes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RepaintBoundary(
                            key: ValueKey(r.id),
                            child: _ResumeCard(
                              resume: r,
                              onTap: () => context.push('${RouteNames.resumePreview}/${r.id}'),
                              onEdit: () => context.push('${RouteNames.resumeEditor}/${r.id}'),
                              onDuplicate: () =>
                                  ref.read(resumeListProvider.notifier).duplicate(r.id),
                              onDelete: () => _confirmDelete(r),
                              onQuickAts: () async {
                                final full = await ResumeService().get(r.id);
                                if (context.mounted) {
                                  AtsQuickScoreSheet.show(context, full);
                                }
                              },
                              onMatchJd: () => context.push(
                                RouteNames.jdMatcher,
                                extra: r.id,
                              ),
                              onSharePdf: () async {
                                final full = await ResumeService().get(r.id);
                                await PdfExportService.exportAndShare(full);
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.resume,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.onQuickAts,
    required this.onMatchJd,
    required this.onSharePdf,
  });

  final ResumeSummary resume;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onQuickAts;
  final VoidCallback onMatchJd;
  final VoidCallback onSharePdf;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _parseColor(resume.themeColor).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _parseColor(resume.themeColor).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.article_rounded, color: _parseColor(resume.themeColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          resume.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (resume.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (resume.headline != null && resume.headline!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      resume.headline!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Updated ${_relativeTime(resume.updatedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                  case 'ats':
                    onQuickAts();
                  case 'jd':
                    onMatchJd();
                  case 'pdf':
                    onSharePdf();
                  case 'duplicate':
                    onDuplicate();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
                ),
                PopupMenuItem(
                  value: 'ats',
                  child: Row(children: [Icon(Icons.bolt_rounded, color: AppColors.amber, size: 18), SizedBox(width: 10), Text('1-Tap ATS Check')]),
                ),
                PopupMenuItem(
                  value: 'jd',
                  child: Row(children: [Icon(Icons.troubleshoot_rounded, color: AppColors.cyan, size: 18), SizedBox(width: 10), Text('Match with Job')]),
                ),
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 10), Text('Share PDF')]),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(children: [Icon(Icons.copy_rounded, size: 18), SizedBox(width: 10), Text('Duplicate')]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18), SizedBox(width: 10), Text('Delete', style: TextStyle(color: AppColors.danger))]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    try {
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('No resumes yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Build your first resume in minutes with our deterministic ATS scoring assistant.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Create first resume',
              icon: Icons.add_rounded,
              expand: false,
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
