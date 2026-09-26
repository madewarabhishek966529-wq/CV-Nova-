import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/ats_provider.dart';
import '../../providers/resume_list_provider.dart';
import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import 'glass_card.dart';
import 'gradient_button.dart';

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BackupRestoreDialog(),
    );
  }

  @override
  ConsumerState<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  final _importController = TextEditingController();
  bool _exporting = false;
  bool _importing = false;
  String? _statusMessage;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    setState(() => _exporting = true);
    try {
      final jsonStr = await BackupService.generateBackupJson();
      await Share.share(jsonStr, subject: 'CVNova Resumes Backup');
      if (mounted) {
        setState(() => _statusMessage = 'Backup ready to save or share! 📦');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Export failed: $e');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restoreBackup() async {
    final text = _importController.text.trim();
    if (text.isEmpty) {
      setState(() => _statusMessage = 'Please paste a valid JSON backup string.');
      return;
    }

    setState(() => _importing = true);
    try {
      final counts = await BackupService.restoreFromJson(text);
      ref.read(resumeListProvider.notifier).load();
      ref.read(atsProvider.notifier).load();

      if (mounted) {
        setState(() {
          _statusMessage =
              'Success! Restored ${counts["resumes"]} resumes & ${counts["ats"]} ATS records. 🎉';
          _importController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Failed to parse backup: $e');
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _importController.text = data.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1220) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0x38FFFFFF) : const Color(0x28000000),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.backup_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Backup & Restore',
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
            const SizedBox(height: 12),
            Text(
              'Export all your resumes and ATS history into a single portable backup file, or restore on a new device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // Export Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Data',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text('Save a copy of your resumes to file, drive, or clipboard.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: _exporting ? 'Exporting...' : 'Export All Resumes (JSON)',
                    icon: Icons.ios_share_rounded,
                    gradient: AppGradients.hero,
                    loading: _exporting,
                    onPressed: _exportBackup,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Import Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Restore from Backup',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste_rounded, size: 16),
                        label: const Text('Paste'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _importController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Paste backup JSON string here...',
                      hintStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: _importing ? 'Restoring...' : 'Restore Resumes',
                    icon: Icons.restore_rounded,
                    gradient: AppGradients.cyan,
                    loading: _importing,
                    onPressed: _restoreBackup,
                  ),
                ],
              ),
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
