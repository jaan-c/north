import 'package:flutter/material.dart';
import 'package:north/src/private_gallery_page/private_gallery_page.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PrivateGalleryPage());
  }
}
