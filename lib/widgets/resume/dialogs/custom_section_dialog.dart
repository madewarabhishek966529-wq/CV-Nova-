import 'package:flutter/material.dart';
import '../../../models/resume.dart';
import '../bullet_list_editor.dart';
import '../dialog_shell.dart';

Future<CustomSectionModel?> showCustomSectionDialog(
  BuildContext context, {
  required CustomSectionModel initial,
  bool isNew = false,
}) {
  return showDialog<CustomSectionModel>(
    context: context,
    builder: (_) => _CustomSectionDialog(initial: initial, isNew: isNew),
  );
}

class _CustomSectionDialog extends StatefulWidget {
  const _CustomSectionDialog({required this.initial, required this.isNew});
  final CustomSectionModel initial;
  final bool isNew;

  @override
  State<_CustomSectionDialog> createState() => _CustomSectionDialogState();
}

class _CustomSectionDialogState extends State<_CustomSectionDialog> {
  late final title = TextEditingController(text: widget.initial.title);
  late List<String> content = List.of(widget.initial.content);

  void _save() => Navigator.of(context).pop(
        widget.initial.copyWith(
          title: title.text.trim(),
          content: content.where((c) => c.trim().isNotEmpty).toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add custom section' : 'Edit custom section',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: title, decoration: const InputDecoration(labelText: 'Section title (e.g. Publications)'))),
        Text('Content', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        BulletListEditor(bullets: content, onChanged: (c) => content = c, addLabel: 'Add line'),
      ],
    );
  }
}
