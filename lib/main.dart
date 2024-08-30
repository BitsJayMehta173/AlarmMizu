import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      home: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  String query = '';
  List<Map<String, String>> items = [];
  List<Map<String, String>> filteredItems = [];
  List<String> alarmTimes = []; // Store all alarm times in an array
  Map<String, String>? _currentAlarmItem; // Track the current alarm item

  late AudioPlayer _audioPlayer;
  late AudioCache _audioCache;
  bool _isPlaying = false;
  DateTime? _lastCheckedTime;
  late Timer _alarmCheckTimer;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _alarmTriggeredInBackground = false; // Track if the alarm was triggered

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    filteredItems = items;
    _audioPlayer = AudioPlayer();
    _audioCache = AudioCache(prefix: 'assets/');
    
    // Initialize the notification plugin
    _initializeNotifications();

    // Populate the alarmTimes array
    alarmTimes = items.map((item) => item['alarm']!).toList();

    _startAlarmChecker();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
          _currentAlarmItem = items.firstWhere((item) => item['alarm'] == currentTime);
          _playRingtone();
          _showAlarmNotification();
          _alarmTriggeredInBackground = true;
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

  Future<void> _showAlarmNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel Name
      channelDescription: 'your_channel_description', // Channel Description
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Alarm',
      'Time to take action!',
      platformChannelSpecifics,
    );
  }

  void _showAlarmDialog(BuildContext context) {
    if (_currentAlarmItem == null) return; // Ensure there is an alarm to show

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
                if (_currentAlarmItem != null) {
                  setState(() {
                    items.remove(_currentAlarmItem!);
                    filteredItems.remove(_currentAlarmItem!);
                    alarmTimes = items.map((item) => item['alarm']!).toList(); // Update the alarmTimes array
                  });
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _alarmTriggeredInBackground) {
      _alarmTriggeredInBackground = false;
      _showAlarmDialog(context);
    }
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

  void _editItemName(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = item['name']!;
        return AlertDialog(
          title: Text('Edit Item Name'),
          content: TextField(
            onChanged: (value) {
              newName = value;
            },
            controller: TextEditingController(text: item['name']),
            decoration: InputDecoration(hintText: "Enter new name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  item['name'] = newName;
                  updateSearch(query);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(Map<String, String> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${item['name']}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                setState(() {
                  items.remove(item);
                  updateSearch(query);
                  alarmTimes = items.map((item) => item['alarm']!).toList(); // Update the alarmTimes array
                });
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
    _audioPlayer.dispose();
    _alarmCheckTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Page'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: updateSearch,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item['name']!),
                    subtitle: Text(item['alarm']!.isNotEmpty
                        ? 'Alarm set for ${item['alarm']}'
                        : 'No alarm set'),
                    onTap: () => navigateToDetailPage(context, item['name']!),
                    onLongPress: () => _editItemName(item),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteItem(item),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onFabPressed,
        child: Icon(Icons.add),
      ),
    );
  }
}
