import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InsulinInputDialog extends StatefulWidget {
  final Function(double units, String insulinType, String? notes) onSave;
  final String? initialType;
  final double? initialUnits;
  final String? initialNotes;
  final bool isEditing;

  const InsulinInputDialog({
    Key? key,
    required this.onSave,
    this.initialType,
    this.initialUnits,
    this.initialNotes,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<InsulinInputDialog> createState() => _InsulinInputDialogState();
}

class _InsulinInputDialogState extends State<InsulinInputDialog> {
  final _unitsController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Bolus';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'Bolus';
    _unitsController.text = widget.initialUnits?.toString() ?? '';
    _notesController.text = widget.initialNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Insulin'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип інсуліну
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Insulin Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Bolus', child: Text('Bolus')),
                  DropdownMenuItem(value: 'Basal', child: Text('Basal')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? 'Bolus';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Кількість одиниць
              TextFormField(
                controller: _unitsController,
                decoration: const InputDecoration(
                  labelText: 'Units',
                  border: OutlineInputBorder(),
                  suffixText: 'U',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter insulin units';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Units must be greater than zero';
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
              final units = double.parse(_unitsController.text);
              final notes =
                  _notesController.text.isEmpty ? null : _notesController.text;

              widget.onSave(units, _selectedType, notes);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
