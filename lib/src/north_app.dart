import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/src/authentication_page/authentication_page.dart';
import 'package:north/src/private_gallery_page/private_gallery_page.dart';
import 'package:provider/provider.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  var galleryKey = Uint8List.fromList([]);

  @override
  Widget build(BuildContext context) {
    return _Providers(
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

class _Providers extends StatelessWidget {
  final Widget Function(BuildContext, Widget) builder;
  final Widget child;

  _Providers({this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return FutureProvider(
      create: (_) => AppPreferences.instantiate(),
      builder: builder,
      child: child,
    );
  }
}
