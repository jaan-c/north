import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'media_viewer_page.dart';
import 'thumbnail_grid.dart';

class MediaListingPage extends StatefulWidget {
  final PrivateGallery gallery;
  final String albumName;

  MediaListingPage(this.gallery, this.albumName);

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
      appBar: _appBar(),
      body: _body(context),
    );
  }

  Widget _appBar() {
    return AppBar(
      title: Text(widget.albumName),
      centerTitle: true,
      automaticallyImplyLeading: true,
    );
  }

  Widget _body(BuildContext context) {
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
                  onTap: () => _openMedia(context, m)))
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

  void _openMedia(BuildContext context, Media media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewerPage(widget.gallery, media),
      ),
    );
  }
}
