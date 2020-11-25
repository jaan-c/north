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

  List<Album> albums;

  @override
  void initState() {
    super.initState();
    _initAlbums();
  }

  Future<void> _initAlbums() async {
    final allAlbums = await gallery.getAllAlbums();
    setState(() => albums = allAlbums);
  }

  @override
  Future<void> dispose() async {
    await gallery.clearThumbnailCache();
    await gallery.clearMediaCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        child: albums != null ? _albumGrid() : LinearProgressIndicator(),
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _albumGrid() {
    final datas = albums.map((a) => ThumbnailData.fromAlbum(a));
    return ThumbnailGrid(datas);
  }
}
