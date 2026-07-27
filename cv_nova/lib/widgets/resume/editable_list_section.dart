import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../common/glass_card.dart';

/// A section card wrapping a reorderable, editable list of items of type
/// [T] — the engine behind every repeatable resume section (experience,
/// education, projects, certifications, achievements, languages,
/// references, links, custom sections). Section-specific concerns (what
/// fields an item has, what its edit dialog looks like) are injected via
/// callbacks so this widget itself has zero knowledge of resume domain
/// shapes.
class EditableListSection<T> extends StatelessWidget {
  const EditableListSection({
    super.key,
    required this.title,
    required this.items,
    required this.idOf,
    required this.titleOf,
    required this.subtitleOf,
    required this.onReorder,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.isHidden,
    required this.onToggleHidden,
    this.emptyLabel = 'Nothing added yet',
    this.addLabel = 'Add',
  });

  final String title;
  final List<T> items;
  final String Function(T) idOf;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final void Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function() onAdd;
  final Future<void> Function(T item) onEdit;
  final void Function(T item) onDelete;
  final bool isHidden;
  final VoidCallback onToggleHidden;
  final String emptyLabel;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: isHidden ? 'Hidden on resume — tap to show' : 'Visible — tap to hide',
                icon: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: isHidden ? AppColors.textSecondaryLight : AppColors.indigo,
                ),
                onPressed: onToggleHidden,
              ),
            ],
          ),
          if (isHidden)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Hidden — won\'t appear on the exported resume',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: onReorder,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: ValueKey(idOf(item)),
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.glassBorder(Theme.of(context).brightness)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 4, right: 4),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_indicator_rounded, size: 20),
                    ),
                    title: Text(
                      titleOf(item).isEmpty ? 'Untitled' : titleOf(item),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: subtitleOf(item).isEmpty ? null : Text(subtitleOf(item)),
                    onTap: () => onEdit(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () => onDelete(item),
                    ),
                  ),
                );
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(addLabel),
            ),
          ),
        ],
      ),
    );
  }
}
