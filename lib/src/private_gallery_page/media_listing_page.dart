import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'media_viewer_page.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

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
          return ThumbnailGrid(
            children: [
              for (final media in snapshot.data) _thumbnailTile(media)
            ],
            crossAxisCount: 3,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _thumbnailTile(Media media) {
    return ThumbnailTile(
      loader: () => widget.gallery.loadMedia(media.id),
      onTap: () => _openMedia(context, media),
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
