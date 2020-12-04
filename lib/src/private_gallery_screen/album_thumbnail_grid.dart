import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'thumbnail_grid.dart';

class AlbumThumbnailGrid extends StatefulWidget {
  final PrivateGallery gallery;

  AlbumThumbnailGrid(this.gallery);

  @override
  _AlbumThumbnailGridState createState() => _AlbumThumbnailGridState();
}

class _AlbumThumbnailGridState extends State<AlbumThumbnailGrid> {
  Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = widget.gallery.getAllAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureAlbums,
      builder: (context, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          final datas = snapshot.data
              .map((a) => ThumbnailData(
                  name: a.name,
                  count: a.mediaCount,
                  loader: () => widget.gallery.loadAlbumThumbnail(a.name)))
              .toList();

          return ThumbnailGrid(datas);
        } else {
          return SizedBox();
        }
      },
    );
  }
}
