import 'package:flutter/material.dart';
import '../../../models/resume.dart';
import '../dialog_shell.dart';

Future<EducationItem?> showEducationDialog(
  BuildContext context, {
  required EducationItem initial,
  bool isNew = false,
}) {
  return showDialog<EducationItem>(
    context: context,
    builder: (_) => _EducationDialog(initial: initial, isNew: isNew),
  );
}

class _EducationDialog extends StatefulWidget {
  const _EducationDialog({required this.initial, required this.isNew});
  final EducationItem initial;
  final bool isNew;

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  late final institution = TextEditingController(text: widget.initial.institution);
  late final degree = TextEditingController(text: widget.initial.degree);
  late final field = TextEditingController(text: widget.initial.fieldOfStudy);
  late final startDate = TextEditingController(text: widget.initial.startDate);
  late final endDate = TextEditingController(text: widget.initial.endDate);
  late final grade = TextEditingController(text: widget.initial.grade);
  late final description = TextEditingController(text: widget.initial.description);

  @override
  void dispose() {
    institution.dispose();
    degree.dispose();
    field.dispose();
    startDate.dispose();
    endDate.dispose();
    grade.dispose();
    description.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.initial.copyWith(
        institution: institution.text.trim(),
        degree: degree.text.trim(),
        fieldOfStudy: field.text.trim(),
        startDate: startDate.text.trim(),
        endDate: endDate.text.trim(),
        grade: grade.text.trim(),
        description: description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add education' : 'Edit education',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: institution, decoration: const InputDecoration(labelText: 'Institution'))),
        DialogField(child: TextField(controller: degree, decoration: const InputDecoration(labelText: 'Degree'))),
        DialogField(child: TextField(controller: field, decoration: const InputDecoration(labelText: 'Field of study'))),
        DialogField(
          child: Row(
            children: [
              Expanded(child: TextField(controller: startDate, decoration: const InputDecoration(labelText: 'Start'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: endDate, decoration: const InputDecoration(labelText: 'End'))),
            ],
          ),
        ),
        DialogField(child: TextField(controller: grade, decoration: const InputDecoration(labelText: 'Grade / GPA (optional)'))),
        DialogField(child: TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)'))),
      ],
    );
  }
}
