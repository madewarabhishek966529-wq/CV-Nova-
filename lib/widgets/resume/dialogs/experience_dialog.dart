import 'package:flutter/material.dart';
import '../../../models/resume.dart';
import '../bullet_list_editor.dart';
import '../dialog_shell.dart';

Future<ExperienceItem?> showExperienceDialog(
  BuildContext context, {
  required ExperienceItem initial,
  bool isNew = false,
}) {
  return showDialog<ExperienceItem>(
    context: context,
    builder: (_) => _ExperienceDialog(initial: initial, isNew: isNew),
  );
}

class _ExperienceDialog extends StatefulWidget {
  const _ExperienceDialog({required this.initial, required this.isNew});
  final ExperienceItem initial;
  final bool isNew;

  @override
  State<_ExperienceDialog> createState() => _ExperienceDialogState();
}

class _ExperienceDialogState extends State<_ExperienceDialog> {
  late final company = TextEditingController(text: widget.initial.company);
  late final role = TextEditingController(text: widget.initial.role);
  late final location = TextEditingController(text: widget.initial.location);
  late final startDate = TextEditingController(text: widget.initial.startDate);
  late final endDate = TextEditingController(text: widget.initial.endDate);
  late bool isCurrent = widget.initial.isCurrent;
  late List<String> bullets = List.of(widget.initial.bullets);

  @override
  void dispose() {
    company.dispose();
    role.dispose();
    location.dispose();
    startDate.dispose();
    endDate.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.initial.copyWith(
        company: company.text.trim(),
        role: role.text.trim(),
        location: location.text.trim(),
        startDate: startDate.text.trim(),
        endDate: isCurrent ? '' : endDate.text.trim(),
        isCurrent: isCurrent,
        bullets: bullets.where((b) => b.trim().isNotEmpty).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add experience' : 'Edit experience',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: role, decoration: const InputDecoration(labelText: 'Role / Title'))),
        DialogField(child: TextField(controller: company, decoration: const InputDecoration(labelText: 'Company'))),
        DialogField(child: TextField(controller: location, decoration: const InputDecoration(labelText: 'Location'))),
        DialogField(
          child: Row(
            children: [
              Expanded(child: TextField(controller: startDate, decoration: const InputDecoration(labelText: 'Start (e.g. 2024-01)'))),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: endDate,
                  enabled: !isCurrent,
                  decoration: const InputDecoration(labelText: 'End (e.g. 2025-06)'),
                ),
              ),
            ],
          ),
        ),
        DialogField(
          child: CheckboxListTile(
            value: isCurrent,
            onChanged: (v) => setState(() => isCurrent = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I currently work here'),
          ),
        ),
        Text('Bullet points', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        BulletListEditor(bullets: bullets, onChanged: (b) => bullets = b),
      ],
    );
  }
}
