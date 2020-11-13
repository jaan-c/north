import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'album_grid.dart';

class PrivateGalleryScreen extends StatefulWidget {
  final PrivateGallery gallery;

  PrivateGalleryScreen({@required this.gallery});

  @override
  _PrivateGalleryScreenState createState() => _PrivateGalleryScreenState();
}

class _PrivateGalleryScreenState extends State<PrivateGalleryScreen> {
  PrivateGallery get gallery => widget.gallery;

  List<Album> albums;

  @override
  void initState() async {
    super.initState();

    albums = await gallery.getAllAlbums();
  }

  @override
  Future<void> dispose() async {
    await gallery.clearThumbnailCache();
    await gallery.clearMediaCache();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _appBar(), body: _albumGrid());
  }

  AppBar _appBar() {
    return AppBar(title: Text('Private Gallery'));
  }

  Widget _albumGrid() {
    if (albums == null) {
      return LinearProgressIndicator();
    }

    return AlbumGrid(albums);
  }
}
