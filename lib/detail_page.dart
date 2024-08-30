import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String item;
  final String initialAlarmTime;
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
  TimeOfDay? _selectedTime;
  String? _formattedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = _parseTimeOfDay(widget.initialAlarmTime);
    _formattedTime = widget.initialAlarmTime;
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = RegExp(r'(\d+):(\d+) (AM|PM)');
    final match = format.firstMatch(timeString);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!;
      return TimeOfDay(
        hour: period == 'AM' ? hour : (hour % 12) + 12,
        minute: minute,
      );
    } else {
      return TimeOfDay.now();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime!,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _formattedTime = _formatTimeOfDay(picked);
        widget.onAlarmSet(widget.item, _formattedTime!);
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
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
            Text('Alarm set for: $_formattedTime'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text('Set Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
