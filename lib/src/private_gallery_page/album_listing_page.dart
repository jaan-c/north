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
    futureAlbums = widget.gallery.getAllAlbums();
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
    } else {
      final pluralizedAlbum = 'album${selectedAlbums.length != 1 ? 's' : ''}';

      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: _clearAlbumSelection,
        ),
        title: Text('Selected ${selectedAlbums.length} $pluralizedAlbum'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_rounded),
            onPressed: () => _showDeleteConfirmationDialog(
              context,
              onDelete: _deleteSelectedAlbums,
            ),
          ),
        ],
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context,
      {@required VoidCallback onDelete}) {
    showDialog(
      context: context,
      builder: _deleteDialog,
      barrierDismissible: false,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
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
            padding: EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
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
      borderRadius: BorderRadius.circular(24),
      onTap: mode == ThumbnailTileMode.normal
          ? () => _openAlbum(context, album.name)
          : () => _toggleAlbumSelection(album),
      onLongPress: mode == ThumbnailTileMode.normal
          ? () => _toggleAlbumSelection(album)
          : null,
    );
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

  Future _deleteSelectedAlbums() async {
    final mediasForDeletion = <Media>[];
    for (final album in selectedAlbums) {
      final medias = await widget.gallery.getMediasOfAlbum(album.name);
      mediasForDeletion.addAll(medias);
    }

    for (final media in mediasForDeletion) {
      await widget.gallery.delete(media.id);
    }

    _clearAlbumSelection();
    setState(() {
      futureAlbums = widget.gallery.getAllAlbums();
    });
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
