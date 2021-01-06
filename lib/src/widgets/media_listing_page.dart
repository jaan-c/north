import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'operation_dialog.dart';
import 'prompt_dialog.dart';
import 'selection_model.dart';
import 'text_field_dialog.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

enum _ExtraAppBarActions { rename, copy, move }

class MediaListingPage extends StatefulWidget {
  @override
  _MediaListingPageState createState() => _MediaListingPageState();
}

class _MediaListingPageState extends State<MediaListingPage> {
  FutureQueue<File> thumbnailLoaderQueue;
  SelectionModel<Media> mediaSelection;
  Future<List<Media>> futureMedias;

  @override
  void initState() {
    super.initState();

    thumbnailLoaderQueue = FutureQueue();
    mediaSelection = SelectionModel(singularName: 'media');
    mediaSelection.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gallery = context.read<GalleryModel>();
    futureMedias = gallery.getAlbumMedias(gallery.openedAlbum);

    _resetState();
  }

  @override
  void dispose() {
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
    final gallery = context.watch<GalleryModel>();

    if (mediaSelection.isEmpty) {
      return AppBar(
        title: Text(gallery.openedAlbum),
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
              builder: (context) => _renameDialog(context),
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

  Widget _renameDialog(BuildContext context) {
    return TextFieldDialog(
      title: 'Rename media',
      initialText: mediaSelection.single.name,
      positiveTextButton: 'RENAME',
      onCheckText: (name) => name.trim().isNotEmpty,
      onSubmitText: (newName) => _renameSelectedMedia(context, newName),
    );
  }

  void _onCopy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CopyDialog(
        medias: mediaSelection.toList(),
      ),
      barrierDismissible: false,
    );
  }

  void _onMove(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MoveDialog(
        medias: mediaSelection.toList(),
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
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return ThumbnailGrid(
          builder: (context, ix) => _thumbnailTile(context, snapshot.data[ix]),
          itemCount: snapshot.data.length,
          crossAxisCount: 3,
        );
      },
    );
  }

  Widget _thumbnailTile(BuildContext context, Media media) {
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
          .add(() => context.read<GalleryModel>().loadMediaThumbnail(media.id)),
      mode: mode,
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openMedia(context, media)
          : () => mediaSelection.toggle(media),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => mediaSelection.toggle(media)
          : null,
    );
  }

  void _renameSelectedMedia(BuildContext context, String newName) async {
    final gallery = context.read<GalleryModel>();

    final selectedMedia = mediaSelection.single;
    await gallery.renameMedia(selectedMedia.id, newName);

    _resetState();
  }

  Future<void> _deleteSelectedMedia() async {
    final gallery = context.read<GalleryModel>();

    final ids = mediaSelection.toList().map((m) => m.id).toList();
    await gallery.deleteMedias(ids);

    _resetState();
  }

  void _resetState() {
    setState(() {
      thumbnailLoaderQueue.clear();
      mediaSelection.clear();
    });
  }

  void _openMedia(BuildContext context, Media media) {
    final gallery = context.read<GalleryModel>();
    gallery.openMedia(media.id);
  }
}
