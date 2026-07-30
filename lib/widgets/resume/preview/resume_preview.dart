import 'package:flutter/material.dart';
import '../../../models/resume.dart';

/// Pure rendering of a [Resume] as a document. Used by both the preview
/// screen and (eventually) as the visual reference for PDF export — keeping
/// this a pure function of Resume -> Widget, with no editing affordances,
/// means it can be reused there without modification.
///
/// personal_info and headline are folded into the header block rather than
/// rendered as their own titled sections — that's how every resume
/// template treats them — but they still respect hidden_sections
/// individually (hide personal_info to drop the contact line, hide
/// headline to drop the title under the name).
class ResumePreview extends StatelessWidget {
  const ResumePreview({super.key, required this.resume});

  final Resume resume;

  Color get _accent {
    final hex = resume.themeColor.replaceAll('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4A3AFF);
    }
  }

  bool _hidden(String key) => resume.hiddenSections.contains(key);

  @override
  Widget build(BuildContext context) {
    final bodyOrder =
        resume.sectionOrder.where((k) => k != 'personal_info' && k != 'headline').toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(resume: resume, accent: _accent, hidden: _hidden),
          for (final key in bodyOrder)
            if (!_hidden(key)) _sectionFor(key, resume, _accent),
        ],
      ),
    );
  }

  Widget _sectionFor(String key, Resume r, Color accent) {
    switch (key) {
      case 'summary':
        return _SummarySection(text: r.professionalSummary, accent: accent);
      case 'experience':
        return _ExperienceSection(items: r.experience, accent: accent);
      case 'projects':
        return _ProjectsSection(items: r.projects, accent: accent);
      case 'education':
        return _EducationSection(items: r.education, accent: accent);
      case 'certifications':
        return _CertificationsSection(items: r.certifications, accent: accent);
      case 'achievements':
        return _AchievementsSection(items: r.achievements, accent: accent);
      case 'skills':
        return _TagSection(title: 'Skills', tags: r.skills, accent: accent);
      case 'languages':
        return _LanguagesSection(items: r.languages, accent: accent);
      case 'interests':
        return _TagSection(title: 'Interests', tags: r.interests, accent: accent);
      case 'references':
        return _ReferencesSection(items: r.references, accent: accent);
      case 'links':
        return _LinksSection(items: r.links, accent: accent);
      case 'custom_sections':
        return _CustomSectionsSection(items: r.customSections, accent: accent);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------

const _ink = Color(0xFF14172A);
const _muted = Color(0xFF6B7280);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Container(height: 1.4, color: accent.withOpacity(0.25)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.resume, required this.accent, required this.hidden});
  final Resume resume;
  final Color accent;
  final bool Function(String) hidden;

  @override
  Widget build(BuildContext context) {
    final info = resume.personalInfo;
    final showContact = !hidden('personal_info');
    final showHeadline = !hidden('headline') &&
        resume.headline != null &&
        resume.headline!.trim().isNotEmpty;

    final contactParts = [info.email, info.phone, info.location, info.website]
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.fullName.trim().isEmpty ? 'Your Name' : info.fullName,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _ink),
        ),
        if (showHeadline) ...[
          const SizedBox(height: 4),
          Text(resume.headline!, style: TextStyle(fontSize: 15, color: accent, fontWeight: FontWeight.w600)),
        ],
        if (showContact && contactParts.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(contactParts.join('   ·   '), style: const TextStyle(fontSize: 12.5, color: _muted)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.text, required this.accent});
  final String? text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Professional Summary', accent: accent),
        Text(text!, style: const TextStyle(fontSize: 13.5, color: _ink, height: 1.5)),
      ],
    );
  }
}

class _ExperienceSection extends StatelessWidget {
  const _ExperienceSection({required this.items, required this.accent});
  final List<ExperienceItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Experience', accent: accent),
        for (final e in items) _ExperienceEntry(item: e),
      ],
    );
  }
}

class _ExperienceEntry extends StatelessWidget {
  const _ExperienceEntry({required this.item});
  final ExperienceItem item;

  @override
  Widget build(BuildContext context) {
    final dateRange = item.isCurrent ? '${item.startDate} — Present' : '${item.startDate} — ${item.endDate}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: item.role, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _ink)),
                    if (item.company.isNotEmpty)
                      TextSpan(text: '  ·  ${item.company}', style: const TextStyle(fontSize: 13.5, color: _ink)),
                  ]),
                ),
              ),
              Text(dateRange, style: const TextStyle(fontSize: 11.5, color: _muted)),
            ],
          ),
          if (item.location.isNotEmpty)
            Text(item.location, style: const TextStyle(fontSize: 11.5, color: _muted)),
          for (final bullet in item.bullets)
            if (bullet.trim().isNotEmpty) _BulletLine(bullet),
        ],
      ),
    );
  }
}

class _ProjectsSection extends StatelessWidget {
  const _ProjectsSection({required this.items, required this.accent});
  final List<ProjectItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Projects', accent: accent),
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _ink)),
                  if (p.techStack.isNotEmpty)
                    TextSpan(text: '  ·  ${p.techStack.join(', ')}', style: const TextStyle(fontSize: 12, color: _muted)),
                ])),
                if (p.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.description, style: const TextStyle(fontSize: 12.5, color: _ink, height: 1.4)),
                  ),
                for (final bullet in p.bullets)
                  if (bullet.trim().isNotEmpty) _BulletLine(bullet),
              ],
            ),
          ),
      ],
    );
  }
}

class _EducationSection extends StatelessWidget {
  const _EducationSection({required this.items, required this.accent});
  final List<EducationItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Education', accent: accent),
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.degree.isEmpty ? e.institution : '${e.degree}${e.fieldOfStudy.isEmpty ? '' : ', ${e.fieldOfStudy}'}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _ink),
                      ),
                      Text(
                        [e.institution, if (e.grade.isNotEmpty) 'Grade: ${e.grade}'].join('  ·  '),
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                Text('${e.startDate} — ${e.endDate}', style: const TextStyle(fontSize: 11.5, color: _muted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CertificationsSection extends StatelessWidget {
  const _CertificationsSection({required this.items, required this.accent});
  final List<CertificationItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Certifications', accent: accent),
        for (final c in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
              if (c.issuer.isNotEmpty)
                TextSpan(text: '  ·  ${c.issuer}', style: const TextStyle(fontSize: 12, color: _muted)),
              if (c.issueDate.isNotEmpty)
                TextSpan(text: '  ·  ${c.issueDate}', style: const TextStyle(fontSize: 11.5, color: _muted)),
            ])),
          ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({required this.items, required this.accent});
  final List<AchievementItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Achievements', accent: accent),
        for (final a in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
                  if (a.date.isNotEmpty)
                    TextSpan(text: '  ·  ${a.date}', style: const TextStyle(fontSize: 11.5, color: _muted)),
                ])),
                if (a.description.isNotEmpty)
                  Text(a.description, style: const TextStyle(fontSize: 12.5, color: _ink, height: 1.4)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LanguagesSection extends StatelessWidget {
  const _LanguagesSection({required this.items, required this.accent});
  final List<LanguageItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Languages', accent: accent),
        Text(
          items.map((l) => '${l.name} (${l.proficiency})').join('   ·   '),
          style: const TextStyle(fontSize: 12.5, color: _ink),
        ),
      ],
    );
  }
}

class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({required this.items, required this.accent});
  final List<ReferenceItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('References', accent: accent),
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
              if (r.relationship.isNotEmpty)
                TextSpan(text: '  ·  ${r.relationship}', style: const TextStyle(fontSize: 12, color: _muted)),
              if (r.contact.isNotEmpty)
                TextSpan(text: '  ·  ${r.contact}', style: const TextStyle(fontSize: 12, color: _muted)),
            ])),
          ),
      ],
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.items, required this.accent});
  final List<LinkItemModel> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Links', accent: accent),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: items
              .map((l) => Text(
                    '${l.label}: ${l.url}',
                    style: TextStyle(fontSize: 12, color: accent, decoration: TextDecoration.underline),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _CustomSectionsSection extends StatelessWidget {
  const _CustomSectionsSection({required this.items, required this.accent});
  final List<CustomSectionModel> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items) ...[
          _SectionTitle(s.title.isEmpty ? 'Additional' : s.title, accent: accent),
          for (final line in s.content)
            if (line.trim().isNotEmpty) _BulletLine(line),
        ],
      ],
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.title, required this.tags, required this.accent});
  final String title;
  final List<String> tags;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title, accent: accent),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 8),
            child: Icon(Icons.circle, size: 4, color: _muted),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: _ink, height: 1.4))),
        ],
      ),
    );
  }
}
