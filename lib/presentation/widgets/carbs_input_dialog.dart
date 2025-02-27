import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CarbsInputDialog extends StatefulWidget {
  final Function(double grams, String? mealType, String? notes) onSave;
  final double? initialGrams;
  final String? initialMealType;
  final String? initialNotes;
  final bool isEditing;

  const CarbsInputDialog({
    Key? key,
    required this.onSave,
    this.initialGrams,
    this.initialMealType,
    this.initialNotes,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<CarbsInputDialog> createState() => _CarbsInputDialogState();
}

class _CarbsInputDialogState extends State<CarbsInputDialog> {
  final _gramsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedMealType;
  final _formKey = GlobalKey<FormState>();

  final _mealTypes = const ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? 'Snack';
    _gramsController.text = widget.initialGrams?.toString() ?? '';
    _notesController.text = widget.initialNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Carbs'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип прийому їжі
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    _mealTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Кількість вуглеводів
              TextFormField(
                controller: _gramsController,
                decoration: const InputDecoration(
                  labelText: 'Carbs',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter carb amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Carbs must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Нотатки
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final grams = double.parse(_gramsController.text);
              final notes =
                  _notesController.text.isEmpty ? null : _notesController.text;

              widget.onSave(grams, _selectedMealType, notes);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
