import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'album_listing_page.dart';
import 'authentication_page.dart';
import 'gallery_model.dart';
import 'media_listing_page.dart';
import 'media_view_page.dart';
import 'models_provider.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  @override
  Widget build(BuildContext context) {
    return ModelsProvider(
      builder: (_, __) => _app(context),
    );
  }

  Widget _app(BuildContext context) {
    final gallery = context.watch<GalleryModel>();

    return MaterialApp(
      home: Navigator(
        pages: [
          if (!gallery.isOpen)
            MaterialPage(child: AuthenticationPage())
          else ...[
            MaterialPage(child: AlbumListingPage()),
            if (gallery.openedAlbum.isNotEmpty)
              MaterialPage(child: MediaListingPage()),
            if (gallery.openedMedia != null)
              MaterialPage(child: MediaViewerPage()),
          ],
        ],
        onPopPage: (route, result) => route.didPop(result),
      ),
    );
  }
}
