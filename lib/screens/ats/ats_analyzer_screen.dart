import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/resume_analysis.dart';
import '../../providers/ats_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/score_ring.dart';

/// The PDF upload + ATS scoring screen. Reachable from the dashboard's
/// ATS Score card, whether or not an analysis exists yet.
class AtsAnalyzerScreen extends ConsumerStatefulWidget {
  const AtsAnalyzerScreen({super.key});

  @override
  ConsumerState<AtsAnalyzerScreen> createState() => _AtsAnalyzerScreenState();
}

class _AtsAnalyzerScreenState extends ConsumerState<AtsAnalyzerScreen> {
  final _keywordsController = TextEditingController();
  PlatformFile? _pickedFile;
  String? _pickError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(atsProvider.notifier).load());
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _pickError = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true, // needed on web + guarantees bytes are populated
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {}
    }
    if (bytes == null) {
      setState(
          () => _pickError = "Couldn't read that file — try picking it again.");
      return;
    }
    setState(() => _pickedFile = PlatformFile(
          name: file.name,
          size: file.size,
          bytes: bytes,
          path: file.path,
        ));
  }

  Future<void> _analyze() async {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return;

    final keywords = _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    final result = await ref.read(atsProvider.notifier).analyze(
          fileBytes: file.bytes!,
          filename: file.name,
          targetKeywords: keywords.isEmpty ? null : keywords,
        );

    if (result != null && mounted) {
      setState(() => _pickedFile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(atsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ATS Resume Checker')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload a resume PDF to check it',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Scored on formatting, keyword coverage, and impact — the '
                'same signals a real ATS keyword scan looks for.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickFile,
                      child: DottedUploadTarget(
                        fileName: _pickedFile?.name,
                      ),
                    ),
                    if (_pickError != null) ...[
                      const SizedBox(height: 8),
                      Text(_pickError!,
                          style:
                              const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keywordsController,
                      decoration: const InputDecoration(
                        labelText: 'Target keywords (optional)',
                        hintText: 'e.g. python, aws, leadership',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paste a few keywords from a job posting to score keyword match against it. '
                      'Left blank, a general keyword set is used instead.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Analyze resume',
                      icon: Icons.insights_rounded,
                      loading: state.analyzing,
                      onPressed: _pickedFile == null ? null : _analyze,
                    ),
                  ],
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(state.error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              if (state.latest != null) ...[
                const SizedBox(height: 24),
                Text('Latest result',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _AnalysisResultCard(analysis: state.latest!),
              ],
              if (state.history.length > 1) ...[
                const SizedBox(height: 24),
                Text('History', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...state.history.skip(1).map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ScoreRing(
                                value: a.score.overall / 100,
                                size: 44,
                                strokeWidth: 5,
                                showPercentage: false,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.filename,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    Text(
                                      '${a.score.overall}/100 · ${_formatDate(a.createdAt)}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.analysis});

  final ResumeAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreRing(value: analysis.score.overall / 100, size: 88),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.filename,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${analysis.wordCount} words',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniScore(
                            label: 'Format', value: analysis.score.formatting),
                        const SizedBox(width: 14),
                        _MiniScore(
                            label: 'Keywords', value: analysis.score.keywords),
                        const SizedBox(width: 14),
                        _MiniScore(
                            label: 'Impact', value: analysis.score.impact),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (analysis.feedback.strengths.isNotEmpty) ...[
            const SizedBox(height: 18),
            _FeedbackList(
              title: 'Strengths',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.mint,
              items: analysis.feedback.strengths,
            ),
          ],
          if (analysis.feedback.weaknesses.isNotEmpty) ...[
            const SizedBox(height: 14),
            _FeedbackList(
              title: 'Weaknesses',
              icon: Icons.error_outline_rounded,
              color: AppColors.coral,
              items: analysis.feedback.weaknesses,
            ),
          ],
          if (analysis.feedback.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _FeedbackList(
              title: 'Suggestions',
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.amber,
              items: analysis.feedback.suggestions,
            ),
          ],
          if (analysis.feedback.missingKeywords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Missing keywords',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.feedback.missingKeywords
                  .map((k) => Chip(
                        label: Text(k),
                        backgroundColor: AppColors.coral.withValues(alpha: 0.12),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(
                            color: AppColors.coral, fontSize: 12),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 4),
            child:
                Text('•  $item', style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
      ],
    );
  }
}

/// The tap target for picking a PDF — a dashed drop-zone look, with the
/// picked filename swapped in once something's selected.
class DottedUploadTarget extends StatelessWidget {
  const DottedUploadTarget({super.key, this.fileName});

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    final picked = fileName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: picked ? AppColors.mint : AppColors.indigo.withValues(alpha: 0.4),
          width: 1.4,
        ),
        color: picked ? AppColors.mint.withValues(alpha: 0.06) : Colors.transparent,
      ),
      child: Column(
        children: [
          Icon(
            picked ? Icons.picture_as_pdf_rounded : Icons.upload_file_rounded,
            size: 32,
            color: picked ? AppColors.mint : AppColors.indigo,
          ),
          const SizedBox(height: 10),
          Text(
            picked ? fileName! : 'Tap to choose a PDF resume',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!picked) ...[
            const SizedBox(height: 2),
            Text(
              'Up to 5MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
