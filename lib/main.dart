import 'package:flutter/material.dart';

void main() {
  runApp(NorthApp());
}

class NorthApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'North',
        home: Scaffold(
            appBar: AppBar(title: Text('North')),
            body: Center(child: Text('Hello world!'))));
  }
}
