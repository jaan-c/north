import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'album_listing_page.dart';
import 'authentication_page.dart';
import 'gallery_provider.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  Uint8List key;

  @override
  Widget build(BuildContext context) {
    if (key == null) {
      return MaterialApp(
        home: AuthenticationPage(onSubmitKey: _setKey),
      );
    }

    return GalleryProvider(
      key,
      builder: (_) => MaterialApp(
        home: AlbumListingPage(),
      ),
    );
  }

  void _setKey(Uint8List newKey) {
    setState(() => key = newKey);
  }
}
