import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'media_viewer_page.dart';
import 'selection.dart';
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
  Selection<Media> mediaSelection;

  @override
  void initState() {
    super.initState();
    _loadMedias();
    mediaSelection = Selection(singularName: 'media', setState: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(context),
    );
  }

  Widget _appBar() {
    if (mediaSelection.isEmpty) {
      return AppBar(
        title: Text(widget.albumName),
        centerTitle: true,
        automaticallyImplyLeading: true,
      );
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close_rounded),
        onPressed: mediaSelection.clear,
      ),
      title: Text('${mediaSelection.count} selected ${mediaSelection.name}'),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_rounded),
          onPressed: () => showDialog(
            context: context,
            builder: _deleteSelectionDialog,
            barrierDismissible: false,
          ),
        ),
      ],
    );
  }

  Widget _deleteSelectionDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${mediaSelection.name}?'),
      content: Text(
          'This will permanently delete ${mediaSelection.count} ${mediaSelection.name}.'),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('DELETE'),
          onPressed: () {
            _deleteSelectedMedia();
            Navigator.pop(context);
          },
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    ThumbnailTileMode mode;
    if (mediaSelection.isEmpty) {
      mode = ThumbnailTileMode.normal;
    } else {
      mode = mediaSelection.contains(media)
          ? ThumbnailTileMode.selected
          : ThumbnailTileMode.unselected;
    }

    return ThumbnailTile(
      loader: () => widget.gallery.loadMedia(media.id),
      mode: mode,
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openMedia(context, media)
          : () => mediaSelection.toggle(media),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => mediaSelection.toggle(media)
          : null,
    );
  }

  void _loadMedias() {
    setState(() {
      futureMedias = widget.gallery.getMediasOfAlbum(widget.albumName);
    });
  }

  Future<void> _deleteSelectedMedia() async {
    for (final media in mediaSelection.toList()) {
      await widget.gallery.delete(media.id);
    }

    mediaSelection.clear();
    _loadMedias();
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
