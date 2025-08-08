import 'package:flutter/material.dart';

/// A widget for input and display of tags with chips
class TagsInput extends StatefulWidget {
  final TextEditingController controller;
  final List<String> tags;
  final Function(List<String>) onTagsChanged;
  final String? hintText;
  final int? maxTags;
  final List<String>? suggestedTags;

  const TagsInput({
    super.key,
    required this.controller,
    required this.tags,
    required this.onTagsChanged,
    this.hintText,
    this.maxTags,
    this.suggestedTags,
  });

  @override
  State<TagsInput> createState() => _TagsInputState();
}

class _TagsInputState extends State<TagsInput> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus && 
                          widget.suggestedTags != null && 
                          widget.suggestedTags!.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags display
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // Input field
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Enter tags separated by commas...',
            border: const OutlineInputBorder(),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addTagsFromInput,
                  )
                : null,
          ),
          onFieldSubmitted: (_) => _addTagsFromInput(),
          onChanged: (_) => setState(() {}),
        ),
        // Suggested tags
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          _buildSuggestedTags(),
        ],
        // Tags count
        if (widget.maxTags != null) ...[
          const SizedBox(height: 4),
          Text(
            '${widget.tags.length}/${widget.maxTags} tags',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    return Chip(
      label: Text(
        tag,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _removeTag(tag),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildSuggestedTags() {
    final suggestions = widget.suggestedTags!
        .where((tag) => !widget.tags.contains(tag))
        .toList();

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested tags:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: suggestions.map((tag) => _buildSuggestedTagChip(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestedTagChip(String tag) {
    return ActionChip(
      label: Text(
        tag,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () => _addTag(tag),
      backgroundColor: Colors.grey[100],
      side: BorderSide(color: Colors.grey[300]!),
    );
  }

  void _addTagsFromInput() {
    final input = widget.controller.text.trim();
    if (input.isEmpty) return;

    final newTags = input
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty && !widget.tags.contains(tag))
        .toList();

    if (newTags.isNotEmpty) {
      final updatedTags = [...widget.tags];
      
      for (final tag in newTags) {
        if (widget.maxTags == null || updatedTags.length < widget.maxTags!) {
          updatedTags.add(tag);
        }
      }
      
      widget.onTagsChanged(updatedTags);
      widget.controller.clear();
    }
  }

  void _addTag(String tag) {
    if (widget.tags.contains(tag)) return;
    if (widget.maxTags != null && widget.tags.length >= widget.maxTags!) return;

    final updatedTags = [...widget.tags, tag];
    widget.onTagsChanged(updatedTags);
  }

  void _removeTag(String tag) {
    final updatedTags = widget.tags.where((t) => t != tag).toList();
    widget.onTagsChanged(updatedTags);
  }
}
