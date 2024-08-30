import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String item;
  final String initialAlarmTime; // Add this parameter to accept the initial alarm time
  final Function(String, String) onAlarmSet;

  DetailPage({
    required this.item,
    required this.initialAlarmTime,
    required this.onAlarmSet,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialAlarmTime.isNotEmpty) {
      try {
        final timeParts = widget.initialAlarmTime.split(":");
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1].split(" ")[0]);
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      } catch (e) {
        // Handle the error or use a default time
        print('Error parsing time: $e');
        // Optionally set a default time if parsing fails
        selectedTime = TimeOfDay.now();
      }
    }
  }

  void _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _saveAlarm() {
    if (selectedTime != null) {
      widget.onAlarmSet(widget.item, selectedTime!.format(context));
    }
    Navigator.of(context).pop(); // Return to the previous page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              selectedTime == null
                  ? 'No alarm set'
                  : 'Alarm set for: ${selectedTime!.format(context)}',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickTime(context),
              child: Text('Set Alarm'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAlarm,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
