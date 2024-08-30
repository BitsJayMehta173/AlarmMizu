import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'detail_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  List<Map<String, String>> items = [
    {'name': 'Apple', 'alarm': '07:30 AM'},
    {'name': 'Banana', 'alarm': '10:00 AM'},
    {'name': 'Orange', 'alarm': '03:15 PM'},
    {'name': 'Grapes', 'alarm': '05:43 PM'},
    {'name': 'Mango', 'alarm': '11:59 PM'}
  ];
  List<Map<String, String>> filteredItems = [];
  List<String> alarmTimes = []; // Store all alarm times in an array

  late AudioPlayer _audioPlayer;
  late AudioCache _audioCache;
  bool _isPlaying = false;
  DateTime? _lastCheckedTime;
  late Timer _alarmCheckTimer;

  @override
  void initState() {
    super.initState();
    filteredItems = items;
    _audioPlayer = AudioPlayer();
    _audioCache = AudioCache(prefix: 'assets/');
    
    // Populate the alarmTimes array
    alarmTimes = items.map((item) => item['alarm']!).toList();

    _startAlarmChecker();
  }

  void _startAlarmChecker() {
    _alarmCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final currentTime = DateFormat('hh:mm a').format(now);

      // Check if the time has changed to the next minute
      if (_lastCheckedTime == null || now.minute != _lastCheckedTime!.minute) {
        _lastCheckedTime = now;
        print('Checking time: $currentTime'); // Debug: Print the current time

        if (alarmTimes.contains(currentTime)) {
          print('Alarm matched!'); // Debug: Alarm time matched
          _playRingtone();
          _showAlarmDialog(context);
        }
      }
    });
  }

  void _playRingtone() async {
    if (!_isPlaying) {
      final url = await _audioCache.load('ringtone.mp3');
      _audioPlayer.setReleaseMode(ReleaseMode.loop); // Set the player to loop the sound
      await _audioPlayer.play(DeviceFileSource(url.path));

      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _stopRingtone() {
    if (_isPlaying) {
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _showAlarmDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Alarm'),
          content: Text('Time to take action!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                _stopRingtone();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateSearch(String newQuery) {
    setState(() {
      query = newQuery;
      filteredItems = items
          .where((item) => item['name']!
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void navigateToDetailPage(BuildContext context, String itemName) {
    final selectedItem = items.firstWhere((element) => element['name'] == itemName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          item: selectedItem['name']!,
          initialAlarmTime: selectedItem['alarm']!,
          onAlarmSet: (String item, String alarmTime) {
            setState(() {
              items.firstWhere((element) => element['name'] == item)['alarm'] = alarmTime;
              updateSearch(query);
              alarmTimes = items.map((item) => item['alarm']!).toList(); // Update the alarmTimes array
            });
          },
        ),
      ),
    );
  }

  void addItem(String newItem) {
    setState(() {
      items.add({'name': newItem, 'alarm': ''});
      updateSearch(query);
    });
  }

  void onFabPressed() {
    showDialog(
      context: context,
      builder: (context) {
        String inputText = '';
        return AlertDialog(
          title: Text('Add New Item'),
          content: TextField(
            onChanged: (value) {
              inputText = value;
            },
            decoration: InputDecoration(hintText: "Enter item name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (inputText.isNotEmpty) {
                  addItem(inputText);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _alarmCheckTimer.cancel(); // Cancel the timer when the widget is disposed
    if (_isPlaying) {
      _audioPlayer.stop(); // Stop the ringtone if it's still playing
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey, width: 1.5),
          ),
          child: TextField(
            onChanged: (value) => updateSearch(value),
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(filteredItems[index]['name']!),
            subtitle: filteredItems[index]['alarm']!.isNotEmpty
                ? Text('Alarm set for: ${filteredItems[index]['alarm']}')
                : null,
            onTap: () => navigateToDetailPage(context, filteredItems[index]['name']!),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onFabPressed,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
