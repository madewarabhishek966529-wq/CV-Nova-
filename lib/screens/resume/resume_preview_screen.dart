import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/resume_editor_provider.dart';
import '../../widgets/resume/preview/resume_preview.dart';

/// Live because it watches the exact same [resumeEditorProvider] instance
/// the editor screen mutates — no separate fetch, no separate state. Any
/// edit made on the editor screen (including ones still mid-debounce,
/// not yet saved to the server) is reflected here immediately, since both
/// screens read from the same in-memory Resume.
class ResumePreviewScreen extends ConsumerWidget {
  const ResumePreviewScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(resumeEditorProvider(resumeId));
    final resume = state.resume;

    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF05060B)
          : const Color(0xFFE9E9F2),
      body: resume == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ResumePreview(resume: resume),
                  ),
                ),
              ),
            ),
    );
  }
}
