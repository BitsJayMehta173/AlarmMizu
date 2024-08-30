import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  late String alarmTime;

  @override
  void initState() {
    super.initState();
    alarmTime = widget.initialAlarmTime;
  }

  void _selectTime() async {
    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateFormat('hh:mm a').parse(alarmTime),
      ),
    );

    if (selectedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final formattedTime = DateFormat('hh:mm a').format(selectedDateTime);

      setState(() {
        alarmTime = formattedTime;
      });

      widget.onAlarmSet(widget.item, formattedTime);
    }
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
            Text('Current alarm time: $alarmTime'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectTime,
              child: Text('Select Alarm Time'),
            ),
          ],
        ),
      ),
    );
  }
}
