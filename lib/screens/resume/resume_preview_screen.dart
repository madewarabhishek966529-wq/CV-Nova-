import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/resume.dart';
import '../../providers/resume_editor_provider.dart';
import '../../routes/route_names.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../widgets/resume/ats_quick_score_sheet.dart';
import '../../widgets/resume/preview/resume_preview.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  bool _isExporting = false;

  Future<void> _exportPdf(Resume resume) async {
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportAndShare(resume);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeEditorProvider(widget.resumeId));
    final resume = state.resume;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(resume?.title ?? 'Preview'),
        elevation: 0,
        actions: [
          if (resume != null) ...[
            IconButton(
              icon: const Icon(Icons.bolt_rounded, color: AppColors.amber),
              tooltip: 'Instant ATS Check',
              onPressed: () => AtsQuickScoreSheet.show(context, resume),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Resume',
              onPressed: () => context.push('${RouteNames.resumeEditor}/${resume.id}'),
            ),
            IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              tooltip: 'Export & Share PDF',
              onPressed: _isExporting ? null : () => _exportPdf(resume),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF07080E) : const Color(0xFFE2E8F0),
      body: resume == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Fast Actions Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isDark ? const Color(0xFF0F111E) : Colors.white,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _QuickActionChip(
                            icon: Icons.bolt_rounded,
                            label: '1-Tap ATS Check',
                            gradient: AppGradients.amber,
                            onTap: () => AtsQuickScoreSheet.show(context, resume),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Match with Job',
                            gradient: AppGradients.hero,
                            onTap: () => context.push(
                              RouteNames.jdMatcher,
                              extra: resume.id,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _QuickActionChip(
                            icon: Icons.picture_as_pdf_rounded,
                            label: _isExporting ? 'Exporting...' : 'Export PDF',
                            gradient: AppGradients.cyan,
                            onTap: _isExporting ? null : () => _exportPdf(resume),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resume Document Preview Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: RepaintBoundary(
                            child: ResumePreview(resume: resume),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x28000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
