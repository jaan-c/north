import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'media_listing_page.dart';
import 'selection.dart';
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
  Selection<Album> albumSelection;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    albumSelection = Selection(
        singularName: 'album', pluralName: 'albums', setState: setState);
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
        onPressed: albumSelection.clear,
      ),
      title: Text('Selected ${albumSelection.count} ${albumSelection.name}'),
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
            builder: _deleteDialog,
            barrierDismissible: false,
          ),
        ),
      ],
    );
  }

  Widget _renameDialog(BuildContext context) {
    return _RenameAlbumDialog(
      initialName: albumSelection.single.name,
      onRename: (newName) => _renameSelectedAlbum(context, newName),
    );
  }

  Widget _deleteDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${albumSelection.name}?'),
      content: Text(
          'This will permanently delete ${albumSelection.count} ${albumSelection.name}.'),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('DELETE'),
          onPressed: () {
            _deleteSelectedAlbums();
            Navigator.pop(context);
          },
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              children: [
                for (final album in snapshot.data)
                  _thumbnailTile(context, album)
              ],
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
      loader: () => widget.gallery.loadAlbumThumbnail(album.name),
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

  void _loadAlbums() {
    setState(() {
      futureAlbums = widget.gallery.getAllAlbums();
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

    albumSelection.clear();
    _loadAlbums();
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
      final medias = await widget.gallery.getMediasOfAlbum(album.name);
      mediasForDeletion.addAll(medias);
    }

    for (final media in mediasForDeletion) {
      await widget.gallery.delete(media.id);
    }

    albumSelection.clear();
    _loadAlbums();
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

typedef _RenameAlbumCallback = void Function(String newName);

class _RenameAlbumDialog extends StatefulWidget {
  final String initialName;
  final _RenameAlbumCallback onRename;

  _RenameAlbumDialog({@required this.initialName, @required this.onRename});

  @override
  __RenameAlbumDialogState createState() => __RenameAlbumDialogState();
}

class __RenameAlbumDialogState extends State<_RenameAlbumDialog> {
  TextEditingController nameController;
  var isNameValid = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName);
    nameController.addListener(_setIsNameValid);
  }

  void _setIsNameValid() {
    setState(() => isNameValid = nameController.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename album'),
      content: _nameField(context),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text('RENAME'),
          onPressed: isNameValid
              ? () {
                  widget.onRename(nameController.text);
                  Navigator.pop(context);
                }
              : null,
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _nameField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: nameController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(border: OutlineInputBorder()),
      autofocus: true,
      autocorrect: true,
    );
  }
}
