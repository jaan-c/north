import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'media_listing_page.dart';
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
  List<Album> selectedAlbums = [];

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: _body(),
    );
  }

  Widget _appBar(BuildContext context) {
    if (selectedAlbums.isEmpty) {
      return AppBar(title: Text('North'), centerTitle: true);
    }

    final pluralizedAlbum = 'album${selectedAlbums.length != 1 ? 's' : ''}';

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close_rounded),
        onPressed: _clearAlbumSelection,
      ),
      title: Text('Selected ${selectedAlbums.length} $pluralizedAlbum'),
      actions: [
        if (selectedAlbums.length == 1)
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
    final selectedAlbum = selectedAlbums.single;

    return _RenameAlbumDialog(
      initialName: selectedAlbum.name,
      onRename: (newName) => _renameSelectedAlbum(context, newName),
    );
  }

  Widget _deleteDialog(BuildContext context) {
    final pluralizedAlbum = 'album${selectedAlbums.length != 1 ? 's' : ''}';

    return AlertDialog(
      title: Text('Delete $pluralizedAlbum?'),
      content: Text(
          'This will permanently delete ${selectedAlbums.length} selected $pluralizedAlbum.'),
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
          return ThumbnailGrid(
            children: [
              for (final album in snapshot.data) _thumbnailTile(context, album)
            ],
            crossAxisCount: 2,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _thumbnailTile(BuildContext context, Album album) {
    ThumbnailTileMode mode;
    if (selectedAlbums.isEmpty) {
      mode = ThumbnailTileMode.normal;
    } else {
      mode = selectedAlbums.contains(album)
          ? ThumbnailTileMode.selected
          : ThumbnailTileMode.unselected;
    }

    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => widget.gallery.loadAlbumThumbnail(album.name),
      mode: mode,
      margin: EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openAlbum(context, album.name)
          : () => _toggleAlbumSelection(album),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => _toggleAlbumSelection(album)
          : null,
    );
  }

  void _loadAlbums() {
    setState(() {
      futureAlbums = widget.gallery.getAllAlbums();
    });
  }

  void _clearAlbumSelection() {
    setState(() => selectedAlbums = []);
  }

  void _toggleAlbumSelection(Album album) {
    final newSelectedAlbums = selectedAlbums.toList();
    if (newSelectedAlbums.contains(album)) {
      newSelectedAlbums.remove(album);
    } else {
      newSelectedAlbums.add(album);
    }

    setState(() => selectedAlbums = newSelectedAlbums);
  }

  Future<void> _renameSelectedAlbum(
      BuildContext context, String newName) async {
    final selectedAlbum = selectedAlbums.single;
    try {
      await widget.gallery.renameAlbum(selectedAlbum.name, newName);
    } on PrivateGalleryException catch (_) {
      _showFailedToRenameSnackBar(context, newName);
    }

    _clearAlbumSelection();
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
    for (final album in selectedAlbums) {
      final medias = await widget.gallery.getMediasOfAlbum(album.name);
      mediasForDeletion.addAll(medias);
    }

    for (final media in mediasForDeletion) {
      await widget.gallery.delete(media.id);
    }

    _clearAlbumSelection();
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
