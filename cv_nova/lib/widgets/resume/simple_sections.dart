import 'package:flutter/material.dart';
import '../../models/resume.dart';
import '../../theme/app_colors.dart';
import '../common/glass_card.dart';
import 'tag_input.dart';

/// Shared header row (title + hide/show toggle) reused by every simple
/// (non-list) section card.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isHidden, required this.onToggleHidden});
  final String title;
  final bool isHidden;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
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
    );
  }
}

class PersonalInfoSection extends StatefulWidget {
  const PersonalInfoSection({
    super.key,
    required this.info,
    required this.onChanged,
    required this.isHidden,
    required this.onToggleHidden,
  });

  final PersonalInfo info;
  final ValueChanged<PersonalInfo> onChanged;
  final bool isHidden;
  final VoidCallback onToggleHidden;

  @override
  State<PersonalInfoSection> createState() => _PersonalInfoSectionState();
}

class _PersonalInfoSectionState extends State<PersonalInfoSection> {
  late final _fullName = TextEditingController(text: widget.info.fullName);
  late final _email = TextEditingController(text: widget.info.email);
  late final _phone = TextEditingController(text: widget.info.phone);
  late final _location = TextEditingController(text: widget.info.location);
  late final _website = TextEditingController(text: widget.info.website);

  void _emit() {
    widget.onChanged(PersonalInfo(
      fullName: _fullName.text,
      email: _email.text,
      phone: _phone.text,
      location: _location.text,
      website: _website.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Personal Info',
            isHidden: widget.isHidden,
            onToggleHidden: widget.onToggleHidden,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fullName,
            decoration: const InputDecoration(labelText: 'Full name'),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                onChanged: (_) => _emit(),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
                onChanged: (_) => _emit(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _website,
                decoration: const InputDecoration(labelText: 'Website / Portfolio'),
                onChanged: (_) => _emit(),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class HeadlineSection extends StatefulWidget {
  const HeadlineSection({
    super.key,
    required this.headline,
    required this.onChanged,
    required this.isHidden,
    required this.onToggleHidden,
  });

  final String? headline;
  final ValueChanged<String> onChanged;
  final bool isHidden;
  final VoidCallback onToggleHidden;

  @override
  State<HeadlineSection> createState() => _HeadlineSectionState();
}

class _HeadlineSectionState extends State<HeadlineSection> {
  late final _controller = TextEditingController(text: widget.headline ?? '');

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Headline', isHidden: widget.isHidden, onToggleHidden: widget.onToggleHidden),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'e.g. Flutter Developer | AI/ML Enthusiast'),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

class SummarySection extends StatefulWidget {
  const SummarySection({
    super.key,
    required this.summary,
    required this.onChanged,
    required this.isHidden,
    required this.onToggleHidden,
  });

  final String? summary;
  final ValueChanged<String> onChanged;
  final bool isHidden;
  final VoidCallback onToggleHidden;

  @override
  State<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<SummarySection> {
  late final _controller = TextEditingController(text: widget.summary ?? '');

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Professional Summary', isHidden: widget.isHidden, onToggleHidden: widget.onToggleHidden),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'A few sentences on who you are and what you bring.',
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

/// Generic flat string-list section — used for both Skills and Interests.
class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.onChanged,
    required this.isHidden,
    required this.onToggleHidden,
    this.hintText = 'Type and press enter',
  });

  final String title;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final bool isHidden;
  final VoidCallback onToggleHidden;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, isHidden: isHidden, onToggleHidden: onToggleHidden),
          const SizedBox(height: 12),
          TagInput(tags: tags, onChanged: onChanged, hintText: hintText),
        ],
      ),
    );
  }
}
