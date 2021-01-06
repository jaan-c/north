import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'prompt_dialog.dart';
import 'selection_model.dart';
import 'text_field_dialog.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class AlbumListingPage extends StatefulWidget {
  @override
  _AlbumListingPageState createState() => _AlbumListingPageState();
}

class _AlbumListingPageState extends State<AlbumListingPage> {
  FutureQueue<File> thumbnailLoaderQueue;
  SelectionModel<Album> albumSelection;

  @override
  void initState() {
    super.initState();

    thumbnailLoaderQueue = FutureQueue();
    albumSelection =
        SelectionModel(singularName: 'album', pluralName: 'albums');
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
      body: _body(context),
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
            builder: (context) => _deleteSelectionDialog(context),
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

  Widget _deleteSelectionDialog(BuildContext context) {
    return PromptDialog(
      title: 'Delete ${albumSelection.name}?',
      content:
          'This will permanently delete ${albumSelection.count} ${albumSelection.name}',
      positiveButtonText: 'DELETE',
      onPositivePressed: () => _deleteSelectedAlbums(context),
    );
  }

  Widget _body(BuildContext context) {
    final albums = context
        .select<GalleryModel, List<Album>>((gallery) => gallery.allAlbums);

    return Padding(
      child: ThumbnailGrid(
        builder: (context, ix) => _thumbnailTile(context, albums[ix]),
        itemCount: albums.length,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      padding: EdgeInsets.all(16),
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
      loader: () => thumbnailLoaderQueue.add(
          () => context.read<GalleryModel>().loadAlbumThumbnail(album.name)),
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
      thumbnailLoaderQueue.clear();
      albumSelection.clear();
    });
  }

  Future<void> _renameSelectedAlbum(
      BuildContext context, String newName) async {
    final gallery = context.read<GalleryModel>();

    final selectedAlbum = albumSelection.single;
    try {
      await gallery.renameAlbum(selectedAlbum.name, newName);
    } on PrivateGalleryException catch (_) {
      _showSnackBar("Can't rename to an already existing album $newName");
    }

    _resetState();
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _deleteSelectedAlbums(BuildContext context) async {
    final gallery = context.read<GalleryModel>();

    for (final album in albumSelection.toList()) {
      await gallery.deleteAlbum(album.name);
    }

    _resetState();
  }

  void _openAlbum(BuildContext context, String name) {
    final gallery = context.read<GalleryModel>();
    gallery.openAlbum(name);
  }
}
