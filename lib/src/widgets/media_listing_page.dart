import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'media_operation_dialog.dart';
import 'media_view_page.dart';
import 'operation_prompt_dialog.dart';
import 'selection_model.dart';
import 'text_field_dialog.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

enum _OverflowMenuActions { selectAll, deselectAll, rename, copy, move }

class MediaListingPage extends StatefulWidget {
  final Album album;

  MediaListingPage(this.album);

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

    final gallery = Provider.of<GalleryModel>(context, listen: true);
    futureMedias = gallery.getAlbumMedias(widget.album.name);
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
    if (mediaSelection.isEmpty) {
      return AppBar(
        title: Text(widget.album.name),
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
          onPressed: () => _showDeleteSelectionDialog(context),
        ),
        _overflowMenuButton(),
      ],
    );
  }

  Future<void> _showDeleteSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => OperationPromptDialog(
        title: 'Delete ${mediaSelection.name}?',
        description:
            'This will permanently delete ${mediaSelection.count} ${mediaSelection.name}.',
        positiveButtonText: 'DELETE',
        operationDescription:
            'Deleting ${mediaSelection.count} ${mediaSelection.name}',
        onPositivePressed: () => _deleteSelectedMedia(context),
      ),
      barrierDismissible: false,
    );
  }

  Widget _overflowMenuButton() {
    return FutureBuilder(
      future: futureMedias,
      builder: (context, AsyncSnapshot<List<Media>> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return PopupMenuButton<_OverflowMenuActions>(
          itemBuilder: (_) => [
            if (mediaSelection.count != snapshot.data.length)
              PopupMenuItem(
                child: Text('Select All'),
                value: _OverflowMenuActions.selectAll,
              )
            else
              PopupMenuItem(
                child: Text('Deselect All'),
                value: _OverflowMenuActions.deselectAll,
              ),
            if (mediaSelection.isSingle)
              PopupMenuItem(
                child: Text('Rename'),
                value: _OverflowMenuActions.rename,
              ),
            PopupMenuItem(
              child: Text('Copy'),
              value: _OverflowMenuActions.copy,
            ),
            PopupMenuItem(
              child: Text('Move'),
              value: _OverflowMenuActions.move,
            ),
          ],
          onSelected: (action) async {
            switch (action) {
              case _OverflowMenuActions.selectAll:
                mediaSelection.selectAll(snapshot.data);
                break;
              case _OverflowMenuActions.deselectAll:
                mediaSelection.deselectAll();
                break;
              case _OverflowMenuActions.rename:
                await _showRenameSelectionDialog(context);
                break;
              case _OverflowMenuActions.copy:
                await _showCopySelectionDialog(context);
                break;
              case _OverflowMenuActions.move:
                await _showMoveSelectionDialog(context);
                break;
              default:
                throw StateError('Unhandled extra action $action');
            }
          },
        );
      },
    );
  }

  Future<void> _showRenameSelectionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => TextFieldDialog(
        title: 'Rename media',
        initialText: mediaSelection.single.name,
        positiveTextButton: 'RENAME',
        onCheckText: (name) => name.trim().isNotEmpty,
        onSubmitText: (newName) => _renameSelectedMedia(context, newName),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showCopySelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => CopyMediaDialog(
        medias: mediaSelection.toList(),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showMoveSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => MoveMediaDialog(
        medias: mediaSelection.toList(),
      ),
      barrierDismissible: false,
    );
  }

  Widget _body(BuildContext context) {
    return FutureBuilder(
      future: futureMedias,
      builder: (context, AsyncSnapshot<List<Media>> snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error is PrivateGalleryException) {
            Future.delayed(Duration.zero, () => Navigator.pop(context));
            return SizedBox.shrink();
          } else {
            throw snapshot.error;
          }
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

  Future<void> _renameSelectedMedia(
      BuildContext context, String newName) async {
    final gallery = context.read<GalleryModel>();

    final selectedMedia = mediaSelection.single;
    await gallery.renameMedia(selectedMedia.id, newName);

    _resetState();
  }

  Future<void> _deleteSelectedMedia(BuildContext context) async {
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
    final route = MaterialPageRoute(
      builder: (_) => MediaViewPage(media),
    );

    Navigator.of(context).push(route);
  }
}
