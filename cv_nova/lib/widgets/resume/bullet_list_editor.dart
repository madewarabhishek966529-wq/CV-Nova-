import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Editable, reorderable list of plain-text bullets. Used for experience/
/// project bullet points and custom-section content.
class BulletListEditor extends StatefulWidget {
  const BulletListEditor({
    super.key,
    required this.bullets,
    required this.onChanged,
    this.addLabel = 'Add bullet point',
  });

  final List<String> bullets;
  final ValueChanged<List<String>> onChanged;
  final String addLabel;

  @override
  State<BulletListEditor> createState() => _BulletListEditorState();
}

class _BulletListEditorState extends State<BulletListEditor> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.bullets.map((b) => TextEditingController(text: b)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _emit() {
    widget.onChanged(_controllers.map((c) => c.text).toList());
  }

  void _add() {
    setState(() => _controllers.add(TextEditingController()));
    _emit();
  }

  void _removeAt(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
    _emit();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _controllers.removeAt(oldIndex);
      _controllers.insert(newIndex, item);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_controllers.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _reorder,
            itemCount: _controllers.length,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey(_controllers[index]),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.drag_indicator_rounded,
                            size: 18, color: AppColors.textSecondaryLight),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controllers[index],
                        decoration: const InputDecoration(hintText: 'Describe an outcome or task'),
                        maxLines: null,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _removeAt(index),
                    ),
                  ],
                ),
              );
            },
          ),
        TextButton.icon(
          onPressed: _add,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(widget.addLabel),
        ),
      ],
    );
  }
}
