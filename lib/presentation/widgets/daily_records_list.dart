import 'package:flutter/material.dart';
import 'package:glucose_companion/data/models/activity_record.dart';
import 'package:glucose_companion/data/models/carb_record.dart';
import 'package:glucose_companion/data/models/insulin_record.dart';
import 'package:intl/intl.dart';

class DailyRecordsList extends StatelessWidget {
  final List<InsulinRecord> insulinRecords;
  final List<CarbRecord> carbRecords;
  final List<ActivityRecord> activityRecords;
  final Function(InsulinRecord)? onEditInsulin;
  final Function(CarbRecord)? onEditCarb;
  final Function(ActivityRecord)? onEditActivity;
  final Function(String, int)? onDeleteRecord;

  const DailyRecordsList({
    Key? key,
    required this.insulinRecords,
    required this.carbRecords,
    required this.activityRecords,
    this.onEditInsulin,
    this.onEditCarb,
    this.onEditActivity,
    this.onDeleteRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Об'єднуємо всі записи для сортування за часом
    final allRecords = <Map<String, dynamic>>[];

    for (final record in insulinRecords) {
      allRecords.add({
        'type': 'insulin',
        'timestamp': record.timestamp,
        'data': record,
      });
    }

    for (final record in carbRecords) {
      allRecords.add({
        'type': 'carbs',
        'timestamp': record.timestamp,
        'data': record,
      });
    }

    for (final record in activityRecords) {
      allRecords.add({
        'type': 'activity',
        'timestamp': record.timestamp,
        'data': record,
      });
    }

    // Сортуємо за часом, найновіші записи зверху
    allRecords.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    if (allRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No records for today. Use the + button to add insulin, carbs, or activity.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allRecords.length,
      itemBuilder: (context, index) {
        final record = allRecords[index];
        final timeFormat = DateFormat('HH:mm');

        if (record['type'] == 'insulin') {
          final insulinRecord = record['data'] as InsulinRecord;
          return _buildInsulinItem(context, insulinRecord, timeFormat);
        } else if (record['type'] == 'carbs') {
          final carbRecord = record['data'] as CarbRecord;
          return _buildCarbItem(context, carbRecord, timeFormat);
        } else {
          final activityRecord = record['data'] as ActivityRecord;
          return _buildActivityItem(context, activityRecord, timeFormat);
        }
      },
    );
  }

  Widget _buildInsulinItem(
    BuildContext context,
    InsulinRecord record,
    DateFormat timeFormat,
  ) {
    return Dismissible(
      key: Key('insulin_${record.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        if (onDeleteRecord != null && record.id != null) {
          onDeleteRecord!('insulin', record.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.medical_services, color: Colors.white),
          ),
          title: Text(
            '${record.units.toStringAsFixed(1)} U ${record.type}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${timeFormat.format(record.timestamp)}'),
              if (record.notes != null && record.notes!.isNotEmpty)
                Text(
                  'Note: ${record.notes}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
          trailing:
              onEditInsulin != null
                  ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditInsulin!(record),
                  )
                  : const Icon(Icons.chevron_right),
          onTap: () {
            if (onEditInsulin != null) {
              onEditInsulin!(record);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCarbItem(
    BuildContext context,
    CarbRecord record,
    DateFormat timeFormat,
  ) {
    return Dismissible(
      key: Key('carb_${record.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        if (onDeleteRecord != null && record.id != null) {
          onDeleteRecord!('carbs', record.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.restaurant, color: Colors.white),
          ),
          title: Text(
            '${record.grams.toStringAsFixed(0)} g Carbs',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${timeFormat.format(record.timestamp)}'),
              if (record.mealType != null) Text('Meal: ${record.mealType}'),
              if (record.notes != null && record.notes!.isNotEmpty)
                Text(
                  'Note: ${record.notes}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
          trailing:
              onEditCarb != null
                  ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditCarb!(record),
                  )
                  : const Icon(Icons.chevron_right),
          onTap: () {
            if (onEditCarb != null) {
              onEditCarb!(record);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ActivityRecord record,
    DateFormat timeFormat,
  ) {
    return Dismissible(
      key: Key('activity_${record.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(context);
      },
      onDismissed: (direction) {
        if (onDeleteRecord != null && record.id != null) {
          onDeleteRecord!('activity', record.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            child: const Icon(Icons.fitness_center, color: Colors.white),
          ),
          title: Text(
            record.activityType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time: ${timeFormat.format(record.timestamp)}'),
              if (record.notes != null && record.notes!.isNotEmpty)
                Text(
                  'Note: ${record.notes}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
            ],
          ),
          trailing:
              onEditActivity != null
                  ? IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditActivity!(record),
                  )
                  : const Icon(Icons.chevron_right),
          onTap: () {
            if (onEditActivity != null) {
              onEditActivity!(record);
            }
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text(
                'Are you sure you want to delete this record?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
