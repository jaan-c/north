import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'async_queue.dart';
import 'media_listing_page.dart';
import 'prompt_dialog.dart';
import 'selection_controller.dart';
import 'text_field_dialog.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

typedef AlbumTapCallback = void Function(String albumName);

class AlbumListingPage extends StatefulWidget {
  final PrivateGallery gallery;

  AlbumListingPage(this.gallery);

  @override
  _AlbumListingPageState createState() => _AlbumListingPageState();
}

class _AlbumListingPageState extends State<AlbumListingPage> {
  Future<List<Album>> futureAlbums;
  AsyncQueue<File> thumbnailLoaderQueue;
  SelectionController<Album> albumSelection;

  @override
  void initState() {
    super.initState();

    futureAlbums = widget.gallery.getAllAlbums();
    thumbnailLoaderQueue = AsyncQueue();
    albumSelection =
        SelectionController(singularName: 'album', pluralName: 'albums');
    albumSelection.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    thumbnailLoaderQueue.dispose();
    albumSelection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _body(),
    );
  }

  Widget _appBar(BuildContext context) {
    if (albumSelection.isEmpty) {
      return AppBar(title: Text('North'), centerTitle: true);
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close_rounded),
        onPressed: _resetState,
      ),
      title: Text('${albumSelection.count} selected ${albumSelection.name}'),
      actions: [
        if (albumSelection.isSingle)
          IconButton(
            icon: Icon(Icons.edit_rounded),
            onPressed: () => showDialog(
              context: context,
              builder: _renameDialog,
              barrierDismissible: false,
            ),
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

  Widget _renameDialog(BuildContext context) {
    return TextFieldDialog(
      title: 'Rename album',
      initialText: albumSelection.single.name,
      positiveTextButton: 'RENAME',
      onCheckText: (name) => name.trim().isNotEmpty,
      onSubmitText: (newName) => _renameSelectedAlbum(context, newName),
    );
  }

  Widget _deleteSelectionDialog() {
    return PromptDialog(
      title: 'Delete ${albumSelection.name}?',
      content:
          'This will permanently delete ${albumSelection.count} ${albumSelection.name}',
      positiveButtonText: 'DELETE',
      onPositivePressed: _deleteSelectedAlbums,
    );
  }

  Widget _body() {
    return FutureBuilder(
      future: futureAlbums,
      builder: (context, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          return Padding(
            child: ThumbnailGrid(
              builder: (context, ix) =>
                  _thumbnailTile(context, snapshot.data[ix]),
              itemCount: snapshot.data.length,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            padding: EdgeInsets.all(16),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _thumbnailTile(BuildContext context, Album album) {
    ThumbnailTileMode mode;
    if (albumSelection.isEmpty) {
      mode = ThumbnailTileMode.normal;
    } else {
      mode = albumSelection.contains(album)
          ? ThumbnailTileMode.selected
          : ThumbnailTileMode.unselected;
    }

    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => thumbnailLoaderQueue
          .add(() => widget.gallery.loadAlbumThumbnail(album.name)),
      mode: mode,
      borderRadius: BorderRadius.circular(24),
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openAlbum(context, album.name)
          : () => albumSelection.toggle(album),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => albumSelection.toggle(album)
          : null,
    );
  }

  void _resetState() {
    setState(() {
      futureAlbums = widget.gallery.getAllAlbums();
      thumbnailLoaderQueue.clear();
      albumSelection.clear();
    });
  }

  Future<void> _renameSelectedAlbum(
      BuildContext context, String newName) async {
    final selectedAlbum = albumSelection.single;
    try {
      await widget.gallery.renameAlbum(selectedAlbum.name, newName);
    } on PrivateGalleryException catch (_) {
      _showFailedToRenameSnackBar(context, newName);
    }

    _resetState();
  }

  void _showFailedToRenameSnackBar(BuildContext context, String newName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Can't rename to an already existing album $newName"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deleteSelectedAlbums() async {
    final mediasForDeletion = <Media>[];
    for (final album in albumSelection.toList()) {
      final medias = await widget.gallery.getAlbumMedias(album.name);
      mediasForDeletion.addAll(medias);
    }

    for (final media in mediasForDeletion) {
      await widget.gallery.delete(media.id);
    }

    _resetState();
  }

  void _openAlbum(BuildContext context, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaListingPage(widget.gallery, name),
      ),
    );
  }
}