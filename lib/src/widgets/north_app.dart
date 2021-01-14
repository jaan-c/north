import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'album_listing_page.dart';
import 'authentication_model.dart';
import 'authentication_page.dart';
import 'models_provider.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  @override
  Widget build(BuildContext context) {
    return ModelsProvider(builder: _app);
  }

  Widget _app(BuildContext context) {
    final auth = context.watch<AuthenticationModel>();

    return MaterialApp(
      home: auth.status != AuthenticationStatus.open
          ? AuthenticationPage()
          : AlbumListingPage(),
    );
  }
}
