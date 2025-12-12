import 'package:flutter/material.dart';
import '../../../models/category.dart';

class AddCategoryDialog extends StatefulWidget {
  final Function(String name, String color) onAdd;

  const AddCategoryDialog({super.key, required this.onAdd});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _controller = TextEditingController();
  String _selectedColor = 'blue';
  bool _isLandscape = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = _isLandscape ? screenWidth * 0.5 : double.infinity;

    return AlertDialog(
      scrollable: true,
      insetPadding: EdgeInsets.symmetric(
        horizontal: _isLandscape ? 40 : 16,
        vertical: 24,
      ),
      title: Row(
        children: [
          Icon(Icons.add, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Add Category'),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Field
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              maxLength: 20,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Color Picker
            Text('Choose Color:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: CategoryColors.allColors.map((color) {
                final isSelected = color == _selectedColor;
                final colorValue = CategoryColors.fromString(color);

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColor = color);
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: colorValue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorValue.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isValid
              ? () {
                  widget.onAdd(_controller.text.trim(), _selectedColor);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
