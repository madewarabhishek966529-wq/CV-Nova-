import 'package:flutter/material.dart';
import '../../../models/resume.dart';
import '../dialog_shell.dart';

// ---------------------------------------------------------------------
// Certification
// ---------------------------------------------------------------------

Future<CertificationItem?> showCertificationDialog(
  BuildContext context, {
  required CertificationItem initial,
  bool isNew = false,
}) {
  return showDialog<CertificationItem>(
    context: context,
    builder: (_) => _CertificationDialog(initial: initial, isNew: isNew),
  );
}

class _CertificationDialog extends StatefulWidget {
  const _CertificationDialog({required this.initial, required this.isNew});
  final CertificationItem initial;
  final bool isNew;

  @override
  State<_CertificationDialog> createState() => _CertificationDialogState();
}

class _CertificationDialogState extends State<_CertificationDialog> {
  late final name = TextEditingController(text: widget.initial.name);
  late final issuer = TextEditingController(text: widget.initial.issuer);
  late final issueDate = TextEditingController(text: widget.initial.issueDate);
  late final expiryDate = TextEditingController(text: widget.initial.expiryDate);
  late final credentialUrl = TextEditingController(text: widget.initial.credentialUrl);

  void _save() => Navigator.of(context).pop(widget.initial.copyWith(
        name: name.text.trim(),
        issuer: issuer.text.trim(),
        issueDate: issueDate.text.trim(),
        expiryDate: expiryDate.text.trim(),
        credentialUrl: credentialUrl.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add certification' : 'Edit certification',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Certification name'))),
        DialogField(child: TextField(controller: issuer, decoration: const InputDecoration(labelText: 'Issuing organization'))),
        DialogField(
          child: Row(children: [
            Expanded(child: TextField(controller: issueDate, decoration: const InputDecoration(labelText: 'Issue date'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: expiryDate, decoration: const InputDecoration(labelText: 'Expiry (optional)'))),
          ]),
        ),
        DialogField(child: TextField(controller: credentialUrl, decoration: const InputDecoration(labelText: 'Credential URL (optional)'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Achievement
// ---------------------------------------------------------------------

Future<AchievementItem?> showAchievementDialog(
  BuildContext context, {
  required AchievementItem initial,
  bool isNew = false,
}) {
  return showDialog<AchievementItem>(
    context: context,
    builder: (_) => _AchievementDialog(initial: initial, isNew: isNew),
  );
}

class _AchievementDialog extends StatefulWidget {
  const _AchievementDialog({required this.initial, required this.isNew});
  final AchievementItem initial;
  final bool isNew;

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog> {
  late final title = TextEditingController(text: widget.initial.title);
  late final description = TextEditingController(text: widget.initial.description);
  late final date = TextEditingController(text: widget.initial.date);

  void _save() => Navigator.of(context).pop(widget.initial.copyWith(
        title: title.text.trim(),
        description: description.text.trim(),
        date: date.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add achievement' : 'Edit achievement',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: title, decoration: const InputDecoration(labelText: 'Title'))),
        DialogField(child: TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description'))),
        DialogField(child: TextField(controller: date, decoration: const InputDecoration(labelText: 'Date (optional)'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Language
// ---------------------------------------------------------------------

Future<LanguageItem?> showLanguageDialog(
  BuildContext context, {
  required LanguageItem initial,
  bool isNew = false,
}) {
  return showDialog<LanguageItem>(
    context: context,
    builder: (_) => _LanguageDialog(initial: initial, isNew: isNew),
  );
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog({required this.initial, required this.isNew});
  final LanguageItem initial;
  final bool isNew;

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  late final name = TextEditingController(text: widget.initial.name);
  late String proficiency = kLanguageProficiencies.contains(widget.initial.proficiency)
      ? widget.initial.proficiency
      : kLanguageProficiencies.first;

  void _save() => Navigator.of(context)
      .pop(widget.initial.copyWith(name: name.text.trim(), proficiency: proficiency));

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add language' : 'Edit language',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Language'))),
        DialogField(
          child: DropdownButtonFormField<String>(
            initialValue: proficiency,
            decoration: const InputDecoration(labelText: 'Proficiency'),
            items: kLanguageProficiencies
                .map((p) => DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1))))
                .toList(),
            onChanged: (v) => setState(() => proficiency = v ?? proficiency),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Reference
// ---------------------------------------------------------------------

Future<ReferenceItem?> showReferenceDialog(
  BuildContext context, {
  required ReferenceItem initial,
  bool isNew = false,
}) {
  return showDialog<ReferenceItem>(
    context: context,
    builder: (_) => _ReferenceDialog(initial: initial, isNew: isNew),
  );
}

class _ReferenceDialog extends StatefulWidget {
  const _ReferenceDialog({required this.initial, required this.isNew});
  final ReferenceItem initial;
  final bool isNew;

  @override
  State<_ReferenceDialog> createState() => _ReferenceDialogState();
}

class _ReferenceDialogState extends State<_ReferenceDialog> {
  late final name = TextEditingController(text: widget.initial.name);
  late final relationship = TextEditingController(text: widget.initial.relationship);
  late final contact = TextEditingController(text: widget.initial.contact);

  void _save() => Navigator.of(context).pop(widget.initial.copyWith(
        name: name.text.trim(),
        relationship: relationship.text.trim(),
        contact: contact.text.trim(),
      ));

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add reference' : 'Edit reference',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Name'))),
        DialogField(child: TextField(controller: relationship, decoration: const InputDecoration(labelText: 'Relationship (e.g. Manager)'))),
        DialogField(child: TextField(controller: contact, decoration: const InputDecoration(labelText: 'Contact (email or phone)'))),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Link
// ---------------------------------------------------------------------

Future<LinkItemModel?> showLinkDialog(
  BuildContext context, {
  required LinkItemModel initial,
  bool isNew = false,
}) {
  return showDialog<LinkItemModel>(
    context: context,
    builder: (_) => _LinkDialog(initial: initial, isNew: isNew),
  );
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.initial, required this.isNew});
  final LinkItemModel initial;
  final bool isNew;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late final label = TextEditingController(text: widget.initial.label);
  late final url = TextEditingController(text: widget.initial.url);

  void _save() =>
      Navigator.of(context).pop(widget.initial.copyWith(label: label.text.trim(), url: url.text.trim()));

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.isNew ? 'Add link' : 'Edit link',
      onSave: _save,
      children: [
        DialogField(child: TextField(controller: label, decoration: const InputDecoration(labelText: 'Label (e.g. GitHub)'))),
        DialogField(child: TextField(controller: url, decoration: const InputDecoration(labelText: 'URL'))),
      ],
    );
  }
}
