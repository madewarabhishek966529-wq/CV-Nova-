import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/resume.dart';
import '../../providers/resume_list_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: state.resumes.length,
                      itemBuilder: (context, index) {
                        final resume = state.resumes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ResumeCard(
                            resume: resume,
                            onOpen: () => context.push('${RouteNames.resumeEditor}/${resume.id}'),
                            onDuplicate: () =>
                                ref.read(resumeListProvider.notifier).duplicate(resume.id),
                            onDelete: () => _confirmDelete(resume),
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
    required this.onOpen,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ResumeSummary resume;
  final VoidCallback onOpen;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(resume.themeColor);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onOpen,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 44,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
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
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (resume.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.indigo.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Primary',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.indigo),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (resume.headline != null && resume.headline!.isNotEmpty)
                    Text(resume.headline!, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    'Updated ${_relativeTime(resume.updatedAt)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'duplicate') onDuplicate();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 56, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text('No resumes yet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create your first resume to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Create resume', expand: false, onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}
