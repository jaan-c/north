import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'authentication_page.dart';
import 'private_gallery_page.dart';
import 'providers.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  var galleryKey = Uint8List.fromList([]);

  @override
  Widget build(BuildContext context) {
    return Providers(
      builder: (_, __) {
        return _app(context);
      },
    );
  }

  Widget _app(BuildContext context) {
    return MaterialApp(
      home: Navigator(
        pages: [
          if (galleryKey.isEmpty)
            MaterialPage(
              child: AuthenticationPage(
                onAuthenticated: (newKey) =>
                    setState(() => galleryKey = newKey),
              ),
            )
          else
            MaterialPage(
              child: PrivateGalleryPage(galleryKey: galleryKey),
            )
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }
}
