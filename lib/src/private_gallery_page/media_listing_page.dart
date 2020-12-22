import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'album_selector_dialog.dart';
import 'async_queue.dart';
import 'media_viewer_page.dart';
import 'operation_queue_controller.dart';
import 'operation_queue_dialog.dart';
import 'prompt_dialog.dart';
import 'selection_controller.dart';
import 'text_field_dialog.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

enum _ExtraAppBarActions { rename, copy, move }

class MediaListingPage extends StatefulWidget {
  final PrivateGallery gallery;
  final String albumName;

  MediaListingPage(this.gallery, this.albumName);

  @override
  _MediaListingPageState createState() => _MediaListingPageState();
}

class _MediaListingPageState extends State<MediaListingPage> {
  Future<List<Media>> futureMedias;
  AsyncQueue<File> thumbnailLoaderQueue;
  SelectionController<Media> mediaSelection;

  @override
  void initState() {
    super.initState();

    futureMedias = widget.gallery.getAlbumMedias(widget.albumName);
    widget.gallery.addListener(_resetState);
    thumbnailLoaderQueue = AsyncQueue();
    mediaSelection = SelectionController(singularName: 'media');
    mediaSelection.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.gallery.removeListener(_resetState);
    thumbnailLoaderQueue.dispose();
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
        onPressed: _resetState,
      ),
      title: Text('${mediaSelection.count} selected ${mediaSelection.name}'),
      actions: [
        IconButton(
          icon: Icon(Icons.delete_rounded),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _deleteSelectionDialog(),
            barrierDismissible: false,
          ),
        ),
        _extraActionsMenuButton(context),
      ],
    );
  }

  Widget _extraActionsMenuButton(BuildContext context) {
    return PopupMenuButton<_ExtraAppBarActions>(
      itemBuilder: (context) => [
        if (mediaSelection.isSingle)
          PopupMenuItem(
            child: Text('Rename'),
            value: _ExtraAppBarActions.rename,
          ),
        PopupMenuItem(child: Text('Copy'), value: _ExtraAppBarActions.copy),
        PopupMenuItem(child: Text('Move'), value: _ExtraAppBarActions.move),
      ],
      onSelected: (action) {
        switch (action) {
          case _ExtraAppBarActions.rename:
            showDialog(
              context: context,
              builder: (_) => _renameDialog(),
              barrierDismissible: false,
            );
            break;
          case _ExtraAppBarActions.copy:
            _onCopy(context);
            break;
          case _ExtraAppBarActions.move:
            _onMove(context);
            break;
          default:
            throw StateError('Unhandled extra action $action');
        }
      },
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

  void _onMove(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlbumSelectorDialog(
        gallery: widget.gallery,
        onSelect: (destinationAlbum) => showDialog(
          context: context,
          builder: (_) => OperationQueueDialog(
            title:
                'Moving ${mediaSelection.count} ${mediaSelection.name} to $destinationAlbum',
            queueController: MoveQueueController(
              gallery: widget.gallery,
              medias: mediaSelection.toList(),
              destinationAlbum: destinationAlbum,
            ),
          ),
          barrierDismissible: false,
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
      loader: () => thumbnailLoaderQueue
          .add(() => widget.gallery.loadMediaThumbnail(media.id)),
      mode: mode,
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openMedia(context, media)
          : () => mediaSelection.toggle(media),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => mediaSelection.toggle(media)
          : null,
    );
  }

  void _renameSelectedMedia(String newName) async {
    final selectedMedia = mediaSelection.single;
    await widget.gallery.renameMedia(selectedMedia.id, newName);

    _resetState();
  }

  Future<void> _deleteSelectedMedia() async {
    for (final media in mediaSelection.toList()) {
      await widget.gallery.delete(media.id);
    }

    _resetState();
  }

  void _resetState() {
    setState(() {
      futureMedias = widget.gallery.getAlbumMedias(widget.albumName);
      thumbnailLoaderQueue.clear();
      mediaSelection.clear();
    });
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
