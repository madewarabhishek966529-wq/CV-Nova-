import 'package:flutter/material.dart';
import '../../../models/resume.dart';
import '../bullet_list_editor.dart';
import '../dialog_shell.dart';
import '../tag_input.dart';

Future<ProjectItem?> showProjectDialog(
  BuildContext context, {
  required ProjectItem initial,
  bool isNew = false,
}) {
  return showDialog<ProjectItem>(
    context: context,
    builder: (_) => _ProjectDialog(initial: initial, isNew: isNew),
  );
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog({required this.initial, required this.isNew});
  final ProjectItem initial;
  final bool isNew;

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  late final name = TextEditingController(text: widget.initial.name);
  late final description = TextEditingController(text: widget.initial.description);
  late final link = TextEditingController(text: widget.initial.link);
  late List<String> techStack = List.of(widget.initial.techStack);
  late List<String> bullets = List.of(widget.initial.bullets);

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    link.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.initial.copyWith(
        name: name.text.trim(),
        description: description.text.trim(),
        link: link.text.trim(),
        techStack: techStack,
        bullets: bullets.where((b) => b.trim().isNotEmpty).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add project' : 'Edit project',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Project name'))),
        DialogField(child: TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: 'Short description'))),
        DialogField(child: TextField(controller: link, decoration: const InputDecoration(labelText: 'Link (optional)'))),
        Text('Tech stack', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DialogField(child: TagInput(tags: techStack, onChanged: (t) => setState(() => techStack = t), hintText: 'e.g. Flutter, Riverpod')),
        Text('Bullet points', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        BulletListEditor(bullets: bullets, onChanged: (b) => bullets = b),
      ],
    );
  }
}
