import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'thumbnail_grid.dart';

typedef AlbumTapCallback = void Function(String albumName);

class AlbumListingPage extends StatefulWidget {
  final PrivateGallery gallery;
  final AlbumTapCallback onAlbumTap;

  AlbumListingPage(this.gallery, {this.onAlbumTap});

  @override
  _AlbumListingPageState createState() => _AlbumListingPageState();
}

class _AlbumListingPageState extends State<AlbumListingPage> {
  Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = widget.gallery.getAllAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  Widget _appBar() {
    return AppBar(title: Text('North'), centerTitle: true);
  }

  Widget _body() {
    return FutureBuilder(
      future: futureAlbums,
      builder: (context, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          final datas = snapshot.data
              .map(
                (a) => ThumbnailData(
                    name: a.name,
                    count: a.mediaCount,
                    loader: () => widget.gallery.loadAlbumThumbnail(a.name),
                    onTap: () => widget.onAlbumTap?.call(a.name)),
              )
              .toList();

          return ThumbnailGrid(
            datas,
            padding: EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            thumbnailBorderRadius: 24,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
