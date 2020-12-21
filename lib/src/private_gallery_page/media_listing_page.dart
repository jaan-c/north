import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'album_selector_dialog.dart';
import 'media_viewer_page.dart';
import 'operation_queue_controller.dart';
import 'operation_queue_dialog.dart';
import 'prompt_dialog.dart';
import 'selection_controller.dart';
import 'text_field_dialog.dart';
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
  SelectionController<Media> mediaSelection;

  @override
  void initState() {
    super.initState();

    mediaSelection = SelectionController(singularName: 'media');
    mediaSelection.addListener(() => setState(() {}));

    _loadMedias();
  }

  @override
  void dispose() {
    mediaSelection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _body(context),
    );
  }

  Widget _appBar(BuildContext context) {
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
        if (mediaSelection.isSingle)
          IconButton(
            icon: Icon(Icons.edit_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _renameDialog(),
              barrierDismissible: false,
            ),
          ),
        IconButton(
          icon: Icon(Icons.copy_rounded),
          onPressed: () => _onCopy(context),
        ),
        IconButton(
          icon: Icon(Icons.delete_rounded),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _deleteSelectionDialog(),
            barrierDismissible: false,
          ),
        ),
      ],
    );
  }

  Widget _renameDialog() {
    return TextFieldDialog(
      title: 'Rename media',
      initialText: mediaSelection.single.name,
      positiveTextButton: 'RENAME',
      onCheckText: (name) => name.trim().isNotEmpty,
      onSubmitText: (newName) => _renameSelectedMedia(newName),
    );
  }

  void _onCopy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlbumSelectorDialog(
        gallery: widget.gallery,
        onSelect: (destinationAlbum) => showDialog(
          context: context,
          builder: (_) => OperationQueueDialog(
            title:
                'Copying ${mediaSelection.count} ${mediaSelection.name} to $destinationAlbum',
            queueController: CopyQueueController(
              gallery: widget.gallery,
              medias: mediaSelection.toList(),
              destinationAlbum: destinationAlbum,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _deleteSelectionDialog() {
    return PromptDialog(
      title: 'Delete ${mediaSelection.name}?',
      content:
          'This will permanently delete ${mediaSelection.count} ${mediaSelection.name}.',
      positiveButtonText: 'DELETE',
      onPositivePressed: _deleteSelectedMedia,
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
            builder: (_, ix) => _thumbnailTile(snapshot.data[ix]),
            itemCount: snapshot.data.length,
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
      loader: () => widget.gallery.loadMediaThumbnail(media.id),
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
      futureMedias = widget.gallery.getAlbumMedias(widget.albumName);
    });
  }

  void _renameSelectedMedia(String newName) async {
    final selectedMedia = mediaSelection.single;
    await widget.gallery.renameMedia(selectedMedia.id, newName);

    mediaSelection.clear();
    _loadMedias();
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
