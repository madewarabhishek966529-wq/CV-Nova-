import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/resume.dart';
import '../../providers/resume_editor_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/resume/dialogs/custom_section_dialog.dart';
import '../../widgets/resume/dialogs/education_dialog.dart';
import '../../widgets/resume/dialogs/experience_dialog.dart';
import '../../widgets/resume/dialogs/project_dialog.dart';
import '../../widgets/resume/dialogs/simple_item_dialogs.dart';
import '../../widgets/resume/editable_list_section.dart';
import '../../widgets/resume/simple_sections.dart';

class ResumeEditorScreen extends ConsumerStatefulWidget {
  const ResumeEditorScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  ConsumerState<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends ConsumerState<ResumeEditorScreen> {
  @override
  void dispose() {
    // Flush any pending debounced edit so nothing is lost when the user
    // navigates away mid-edit.
    ref.read(resumeEditorProvider(widget.resumeId).notifier).saveNow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumeEditorProvider(widget.resumeId));
    final notifier = ref.read(resumeEditorProvider(widget.resumeId).notifier);

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final resume = state.resume;
    if (resume == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(state.error ?? 'Could not load this resume.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _renameResume(context, notifier, resume),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(resume.title, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined, size: 16),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => context.push('${RouteNames.resumePreview}/${widget.resumeId}'),
          ),
          const SizedBox(width: 4),
          _SaveStatusIndicator(status: state.saveStatus),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          buildDefaultDragHandles: false,
          itemCount: resume.sectionOrder.length,
          onReorder: (oldIndex, newIndex) {
            final order = List<String>.of(resume.sectionOrder);
            if (newIndex > oldIndex) newIndex -= 1;
            final key = order.removeAt(oldIndex);
            order.insert(newIndex, key);
            notifier.apply((r) => r.copyWith(sectionOrder: order));
          },
          itemBuilder: (context, index) {
            final key = resume.sectionOrder[index];
            return Padding(
              key: ValueKey(key),
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 18, right: 4),
                      child: Icon(Icons.drag_indicator_rounded,
                          size: 20, color: AppColors.textSecondaryLight),
                    ),
                  ),
                  Expanded(child: _buildSection(context, key, resume, notifier)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _renameResume(
    BuildContext context,
    ResumeEditorNotifier notifier,
    Resume resume,
  ) async {
    final controller = TextEditingController(text: resume.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename resume'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      notifier.apply((r) => r.copyWith(title: newTitle));
    }
  }

  bool _isHidden(Resume resume, String key) => resume.hiddenSections.contains(key);

  void _toggleHidden(ResumeEditorNotifier notifier, Resume resume, String key) {
    final hidden = List<String>.of(resume.hiddenSections);
    if (hidden.contains(key)) {
      hidden.remove(key);
    } else {
      hidden.add(key);
    }
    notifier.apply((r) => r.copyWith(hiddenSections: hidden));
  }

  Widget _buildSection(
    BuildContext context,
    String key,
    Resume resume,
    ResumeEditorNotifier notifier,
  ) {
    final isHidden = _isHidden(resume, key);
    void toggleHidden() => _toggleHidden(notifier, resume, key);

    switch (key) {
      case 'personal_info':
        return PersonalInfoSection(
          info: resume.personalInfo,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          onChanged: (info) => notifier.apply((r) => r.copyWith(personalInfo: info)),
        );

      case 'headline':
        return HeadlineSection(
          headline: resume.headline,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          onChanged: (v) => notifier.apply((r) => r.copyWith(headline: v)),
        );

      case 'summary':
        return SummarySection(
          summary: resume.professionalSummary,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          onChanged: (v) => notifier.apply((r) => r.copyWith(professionalSummary: v)),
        );

      case 'skills':
        return TagSection(
          title: 'Skills',
          tags: resume.skills,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          hintText: 'e.g. Flutter, Python, Figma',
          onChanged: (v) => notifier.apply((r) => r.copyWith(skills: v)),
        );

      case 'interests':
        return TagSection(
          title: 'Interests',
          tags: resume.interests,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          hintText: 'e.g. Open source, Chess, Photography',
          onChanged: (v) => notifier.apply((r) => r.copyWith(interests: v)),
        );

      case 'experience':
        return EditableListSection<ExperienceItem>(
          title: 'Experience',
          items: resume.experience,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.role.isEmpty ? e.company : '${e.role} · ${e.company}',
          subtitleOf: (e) => e.isCurrent ? '${e.startDate} — Present' : '${e.startDate} — ${e.endDate}',
          emptyLabel: 'Add your work experience',
          addLabel: 'Add experience',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<ExperienceItem>.of(r.experience);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(experience: list);
          }),
          onAdd: () async {
            final item = await showExperienceDialog(
              context,
              initial: ExperienceItem(id: _newId()),
              isNew: true,
            );
            if (item != null) {
              notifier.apply((r) => r.copyWith(experience: [...r.experience, item]));
            }
          },
          onEdit: (item) async {
            final updated = await showExperienceDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    experience: r.experience.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier.apply((r) => r.copyWith(
                experience: r.experience.where((e) => e.id != item.id).toList(),
              )),
        );

      case 'projects':
        return EditableListSection<ProjectItem>(
          title: 'Projects',
          items: resume.projects,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.name,
          subtitleOf: (e) => e.techStack.join(', '),
          emptyLabel: 'Showcase what you\'ve built',
          addLabel: 'Add project',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<ProjectItem>.of(r.projects);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(projects: list);
          }),
          onAdd: () async {
            final item = await showProjectDialog(context, initial: ProjectItem(id: _newId()), isNew: true);
            if (item != null) notifier.apply((r) => r.copyWith(projects: [...r.projects, item]));
          },
          onEdit: (item) async {
            final updated = await showProjectDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    projects: r.projects.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier
              .apply((r) => r.copyWith(projects: r.projects.where((e) => e.id != item.id).toList())),
        );

      case 'education':
        return EditableListSection<EducationItem>(
          title: 'Education',
          items: resume.education,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.degree.isEmpty ? e.institution : '${e.degree} · ${e.institution}',
          subtitleOf: (e) => '${e.startDate} — ${e.endDate}',
          emptyLabel: 'Add your education',
          addLabel: 'Add education',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<EducationItem>.of(r.education);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(education: list);
          }),
          onAdd: () async {
            final item =
                await showEducationDialog(context, initial: EducationItem(id: _newId()), isNew: true);
            if (item != null) notifier.apply((r) => r.copyWith(education: [...r.education, item]));
          },
          onEdit: (item) async {
            final updated = await showEducationDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    education: r.education.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier
              .apply((r) => r.copyWith(education: r.education.where((e) => e.id != item.id).toList())),
        );

      case 'certifications':
        return EditableListSection<CertificationItem>(
          title: 'Certifications',
          items: resume.certifications,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.name,
          subtitleOf: (e) => e.issuer,
          addLabel: 'Add certification',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<CertificationItem>.of(r.certifications);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(certifications: list);
          }),
          onAdd: () async {
            final item = await showCertificationDialog(context,
                initial: CertificationItem(id: _newId()), isNew: true);
            if (item != null) {
              notifier.apply((r) => r.copyWith(certifications: [...r.certifications, item]));
            }
          },
          onEdit: (item) async {
            final updated = await showCertificationDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    certifications:
                        r.certifications.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier.apply((r) => r.copyWith(
                certifications: r.certifications.where((e) => e.id != item.id).toList(),
              )),
        );

      case 'achievements':
        return EditableListSection<AchievementItem>(
          title: 'Achievements',
          items: resume.achievements,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.title,
          subtitleOf: (e) => e.date,
          addLabel: 'Add achievement',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<AchievementItem>.of(r.achievements);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(achievements: list);
          }),
          onAdd: () async {
            final item =
                await showAchievementDialog(context, initial: AchievementItem(id: _newId()), isNew: true);
            if (item != null) {
              notifier.apply((r) => r.copyWith(achievements: [...r.achievements, item]));
            }
          },
          onEdit: (item) async {
            final updated = await showAchievementDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    achievements: r.achievements.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier.apply(
              (r) => r.copyWith(achievements: r.achievements.where((e) => e.id != item.id).toList())),
        );

      case 'languages':
        return EditableListSection<LanguageItem>(
          title: 'Languages',
          items: resume.languages,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.name,
          subtitleOf: (e) => e.proficiency,
          addLabel: 'Add language',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<LanguageItem>.of(r.languages);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(languages: list);
          }),
          onAdd: () async {
            final item = await showLanguageDialog(context, initial: LanguageItem(id: _newId()), isNew: true);
            if (item != null) notifier.apply((r) => r.copyWith(languages: [...r.languages, item]));
          },
          onEdit: (item) async {
            final updated = await showLanguageDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    languages: r.languages.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier
              .apply((r) => r.copyWith(languages: r.languages.where((e) => e.id != item.id).toList())),
        );

      case 'references':
        return EditableListSection<ReferenceItem>(
          title: 'References',
          items: resume.references,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.name,
          subtitleOf: (e) => e.relationship,
          addLabel: 'Add reference',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<ReferenceItem>.of(r.references);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(references: list);
          }),
          onAdd: () async {
            final item = await showReferenceDialog(context, initial: ReferenceItem(id: _newId()), isNew: true);
            if (item != null) notifier.apply((r) => r.copyWith(references: [...r.references, item]));
          },
          onEdit: (item) async {
            final updated = await showReferenceDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    references: r.references.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier
              .apply((r) => r.copyWith(references: r.references.where((e) => e.id != item.id).toList())),
        );

      case 'links':
        return EditableListSection<LinkItemModel>(
          title: 'Links',
          items: resume.links,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.label,
          subtitleOf: (e) => e.url,
          addLabel: 'Add link',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<LinkItemModel>.of(r.links);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(links: list);
          }),
          onAdd: () async {
            final item = await showLinkDialog(context, initial: LinkItemModel(id: _newId()), isNew: true);
            if (item != null) notifier.apply((r) => r.copyWith(links: [...r.links, item]));
          },
          onEdit: (item) async {
            final updated = await showLinkDialog(context, initial: item);
            if (updated != null) {
              notifier.apply(
                  (r) => r.copyWith(links: r.links.map((e) => e.id == item.id ? updated : e).toList()));
            }
          },
          onDelete: (item) =>
              notifier.apply((r) => r.copyWith(links: r.links.where((e) => e.id != item.id).toList())),
        );

      case 'custom_sections':
        return EditableListSection<CustomSectionModel>(
          title: 'Custom Sections',
          items: resume.customSections,
          isHidden: isHidden,
          onToggleHidden: toggleHidden,
          idOf: (e) => e.id,
          titleOf: (e) => e.title,
          subtitleOf: (e) => '${e.content.length} line(s)',
          addLabel: 'Add custom section',
          onReorder: (oldI, newI) => notifier.apply((r) {
            final list = List<CustomSectionModel>.of(r.customSections);
            if (newI > oldI) newI -= 1;
            list.insert(newI, list.removeAt(oldI));
            return r.copyWith(customSections: list);
          }),
          onAdd: () async {
            final item = await showCustomSectionDialog(context,
                initial: CustomSectionModel(id: _newId()), isNew: true);
            if (item != null) {
              notifier.apply((r) => r.copyWith(customSections: [...r.customSections, item]));
            }
          },
          onEdit: (item) async {
            final updated = await showCustomSectionDialog(context, initial: item);
            if (updated != null) {
              notifier.apply((r) => r.copyWith(
                    customSections:
                        r.customSections.map((e) => e.id == item.id ? updated : e).toList(),
                  ));
            }
          },
          onDelete: (item) => notifier.apply((r) => r.copyWith(
                customSections: r.customSections.where((e) => e.id != item.id).toList(),
              )),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class _SaveStatusIndicator extends StatelessWidget {
  const _SaveStatusIndicator({required this.status});
  final SaveStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text('Saving…', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case SaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.mint),
            const SizedBox(width: 6),
            Text('Saved', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case SaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.coral),
            const SizedBox(width: 6),
            Text('Save failed', style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case SaveStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
