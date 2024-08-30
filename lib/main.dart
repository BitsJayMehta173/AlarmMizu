import 'package:flutter/material.dart';
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

class _SearchPageState extends State<SearchPage> {
  String query = '';
  List<Map<String, String>> items = [
    {'name': 'Apple', 'alarm': ''},
    {'name': 'Banana', 'alarm': ''},
    {'name': 'Orange', 'alarm': ''},
    {'name': 'Grapes', 'alarm': ''},
    {'name': 'Mango', 'alarm': ''}
  ];
  List<Map<String, String>> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = items;
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
          initialAlarmTime: selectedItem['alarm']!, // Pass the current alarm time
          onAlarmSet: (String item, String alarmTime) {
            setState(() {
              items.firstWhere((element) => element['name'] == item)['alarm'] =
                  alarmTime;
              updateSearch(query); // Update search to reflect the new alarm
            });
          },
        ),
      ),
    );
  }

  void addItem(String newItem) {
    setState(() {
      items.add({'name': newItem, 'alarm': ''});
      updateSearch(query); // Re-filter the list based on the current query
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
            onTap: () =>
                navigateToDetailPage(context, filteredItems[index]['name']!),
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
