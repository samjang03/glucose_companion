import 'package:flutter/material.dart';

class ActivityInputDialog extends StatefulWidget {
  final Function(String activityType, String? notes) onSave;
  final String? initialActivityType;
  final String? initialNotes;
  final bool isEditing;

  const ActivityInputDialog({
    Key? key,
    required this.onSave,
    this.initialActivityType,
    this.initialNotes,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<ActivityInputDialog> createState() => _ActivityInputDialogState();
}

class _ActivityInputDialogState extends State<ActivityInputDialog> {
  late String _selectedActivityType;
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Використовуємо список активностей з вашого датасету
  final _activityTypes = const [
    'Indoor climbing',
    'Run',
    'Strength training',
    'Swim',
    'Bike',
    'Dancing',
    'Stairclimber',
    'Spinning',
    'Walking',
    'HIIT',
    'Outdoor Bike',
    'Walk',
    'Aerobic Workout',
    'Tennis',
    'Workout',
    'Hike',
    'Zumba',
    'Sport',
    'Yoga',
    'Swimming',
    'Weights',
    'Running',
  ];

  @override
  void initState() {
    super.initState();
    _selectedActivityType = widget.initialActivityType ?? _activityTypes[0];
    _notesController.text = widget.initialNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Activity' : 'Record Activity'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Тип активності
              DropdownButtonFormField<String>(
                value: _selectedActivityType,
                decoration: const InputDecoration(
                  labelText: 'Activity Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    _activityTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivityType = value ?? _activityTypes[0];
                  });
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
              final notes =
                  _notesController.text.isEmpty ? null : _notesController.text;

              widget.onSave(_selectedActivityType, notes);

              Navigator.pop(context);
            }
          },
          child: Text(widget.isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}
