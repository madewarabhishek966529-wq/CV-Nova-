import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Chip input for flat string-list sections (skills, interests). Type +
/// Enter (or comma) to add, tap the chip's close icon to remove.
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.hintText = 'Type and press enter',
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String hintText;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (!widget.tags.contains(value)) {
      widget.onChanged([...widget.tags, value]);
    }
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => _remove(tag),
                    ))
                .toList(),
          ),
        if (widget.tags.isNotEmpty) const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: widget.hintText),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _commit(),
          onChanged: (value) {
            if (value.endsWith(',')) {
              _controller.text = value.substring(0, value.length - 1);
              _commit();
            }
          },
        ),
      ],
    );
  }
}
