import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'album_listing_page.dart';
import 'media_listing_page.dart';
import 'media_viewer_page.dart';

class GalleryPageNavigator extends StatefulWidget {
  final PrivateGallery gallery;

  GalleryPageNavigator(this.gallery);

  @override
  _GalleryNavigatorState createState() => _GalleryNavigatorState();
}

class _GalleryNavigatorState extends State<GalleryPageNavigator> {
  String openedAlbum;
  Media openedMedia;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: [
        MaterialPage(
          child: AlbumListingPage(widget.gallery, onAlbumTap: _setOpenedAlbum),
        ),
        if (openedAlbum != null)
          MaterialPage(
            child: MediaListingPage(
              widget.gallery,
              openedAlbum,
              onMediaTap: _setOpenedMedia,
            ),
          ),
        if (openedMedia != null)
          MaterialPage(
            child: MediaViewerPage(widget.gallery, openedMedia),
          ),
      ],
      onPopPage: _onPopPage,
    );
  }

  void _setOpenedAlbum(String albumName) {
    setState(() {
      openedAlbum = albumName;
    });
  }

  void _setOpenedMedia(Media media) {
    setState(() {
      openedMedia = media;
    });
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) {
      return false;
    }

    if (openedMedia != null) {
      setState(() {
        openedMedia = null;
      });
    } else if (openedAlbum != null) {
      setState(() {
        openedAlbum = null;
      });
    } else {
      throw StateError('Nothing to pop.');
    }

    return true;
  }
}
