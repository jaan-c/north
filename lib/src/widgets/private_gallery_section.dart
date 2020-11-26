import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:north/src/widgets/thumbnail_grid.dart';

class PrivateGallerySection extends StatefulWidget {
  final PrivateGallery gallery;

  PrivateGallerySection(this.gallery);

  @override
  _PrivateGallerySectionState createState() => _PrivateGallerySectionState();
}

class _PrivateGallerySectionState extends State<PrivateGallerySection> {
  PrivateGallery get gallery => widget.gallery;

  Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = gallery.getAllAlbums();
  }

  @override
  void dispose() {
    _clearCaches();
    super.dispose();
  }

  Future<void> _clearCaches() async {
    await gallery.clearThumbnailCache();
    await gallery.clearMediaCache();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder(
        future: futureAlbums,
        builder: (_, AsyncSnapshot<List<Album>> snapshot) {
          if (snapshot.hasError) {
            throw StateError('Failed to load albums: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return LinearProgressIndicator();
          }

          return Padding(
            child: _albumGrid(snapshot.data),
            padding: EdgeInsets.symmetric(horizontal: 16),
          );
        },
      ),
    );
  }

  Widget _albumGrid(List<Album> albums) {
    final datas = albums.map((a) => ThumbnailData.fromAlbum(a)).toList();
    return ThumbnailGrid(datas);
  }
}
