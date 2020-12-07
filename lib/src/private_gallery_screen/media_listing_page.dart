import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'thumbnail_grid.dart';

typedef MediaTapCallback = void Function(Media media);

class MediaListingPage extends StatefulWidget {
  final PrivateGallery gallery;
  final String albumName;
  final MediaTapCallback onMediaTap;

  MediaListingPage(this.gallery, this.albumName, {this.onMediaTap});

  @override
  _MediaListingPageState createState() => _MediaListingPageState();
}

class _MediaListingPageState extends State<MediaListingPage> {
  Future<List<Media>> futureMedias;

  @override
  void initState() {
    super.initState();
    futureMedias = widget.gallery.getMediasOfAlbum(widget.albumName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _body(),
    );
  }

  Widget _appBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.albumName),
      centerTitle: true,
    );
  }

  Widget _body() {
    return FutureBuilder(
      future: futureMedias,
      builder: (context, AsyncSnapshot<List<Media>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          final datas = snapshot.data
              .map((m) => ThumbnailData(
                  name: m.name,
                  loader: () => widget.gallery.loadMediaThumbnail(m.id),
                  onTap: () => widget.onMediaTap?.call(m)))
              .toList();

          return ThumbnailGrid(
            datas,
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            thumbnailBorderRadius: 0,
            showThumbnailName: false,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
