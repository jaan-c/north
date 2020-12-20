import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

typedef SelectAlbumCallback = void Function(String selectedAlbum);

class AlbumSelectorDialog extends StatefulWidget {
  final PrivateGallery gallery;
  final SelectAlbumCallback onSelect;

  AlbumSelectorDialog({@required this.gallery, @required this.onSelect});

  @override
  _AlbumSelectorDialogState createState() => _AlbumSelectorDialogState();
}

class _AlbumSelectorDialogState extends State<AlbumSelectorDialog> {
  Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    // Don't add a listener since gallery shouldn't change in album selector.
    futureAlbums = widget.gallery.getAllAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select album'),
      content: _thumbnailGrid(),
      contentPadding: EdgeInsets.fromLTRB(16, 20, 16, 24),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _thumbnailGrid() {
    return FutureBuilder(
      future: futureAlbums,
      builder: (_, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          return ThumbnailGrid(
            builder: (context, ix) =>
                _thumbnailTile(context, snapshot.data[ix]),
            itemCount: snapshot.data.length,
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
    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => widget.gallery.loadAlbumThumbnail(album.name),
      mode: ThumbnailTileMode.normal,
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.pop(context);
        widget.onSelect(album.name);
      },
    );
  }
}
