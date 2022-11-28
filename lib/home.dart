import 'package:MonLienQr/with_gallery.dart';
import 'package:MonLienQr/with_link.dart';
import 'package:flutter/material.dart';

import 'maintenance.dart';

class Home extends StatelessWidget {
  final int selectedIndex;
  const Home({required this.selectedIndex, super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirstRoute(title: 'First Route', selectedIndex: selectedIndex),
    );
  }
}

class FirstRoute extends StatefulWidget {
  FirstRoute({required this.title, required this.selectedIndex});
  final String title;
  final int selectedIndex;

  @override
  _FirstRouteState createState() =>
      _FirstRouteState(selectedIndex: selectedIndex);
}

class _FirstRouteState extends State<FirstRoute> {
  _FirstRouteState({required this.selectedIndex});
  int selectedIndex;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  static const List<Widget> _widgetOptions = <Widget>[
    WithLink(),
    WithGallery()
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Url',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Gallerie',
            ),
          ],
          currentIndex: selectedIndex,
          selectedItemColor: Color.fromARGB(255, 0, 47, 255),
          onTap: _onItemTapped,
        ),
        body: Center(
          child: _widgetOptions.elementAt(selectedIndex),
        ));
  }
}
