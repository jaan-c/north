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
      appBar: _appBar(),
      body: _body(),
    );
  }

  Widget _appBar() {
    if (selectedAlbums.isEmpty) {
      return AppBar(title: Text('North'), centerTitle: true);
    } else {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.close_rounded),
          onPressed: _clearAlbumSelection,
        ),
        title: Text(
            'Selected ${selectedAlbums.length} album${selectedAlbums.length != 1 ? 's' : ''}'),
        centerTitle: true,
      );
    }
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
    setState(() {
      selectedAlbums = [];
    });
  }

  void _toggleAlbumSelection(Album album) {
    final newSelectedAlbums = selectedAlbums.toList();
    if (newSelectedAlbums.contains(album)) {
      newSelectedAlbums.remove(album);
    } else {
      newSelectedAlbums.add(album);
    }

    setState(() {
      selectedAlbums = newSelectedAlbums;
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
