import 'package:flutter/material.dart';

import 'private_gallery_screen.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PrivateGalleryScreen());
  }
}
