import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:north/private_gallery.dart';

class AlbumGrid extends StatelessWidget {
  final List<Album> albums;

  AlbumGrid(this.albums);

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: StaggeredGridView.countBuilder(
        itemBuilder: (_, ix) => _AlbumTile(albums[ix]),
        staggeredTileBuilder: (_) => StaggeredTile.fit(1),
        itemCount: albums.length,
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
      ),
      padding: EdgeInsets.all(8),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;

  _AlbumTile(this.album);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _albumThumbnail(album.thumbnail),
        SizedBox(height: 4),
        _albumName(context, album.name),
      ],
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  Widget _albumThumbnail(File thumbnail) {
    return ClipRRect(
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: FittedBox(
            child: Image.asset('assets/haskell.png'), fit: BoxFit.cover),
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  Widget _albumName(BuildContext context, String name) {
    final textTheme = Theme.of(context).textTheme;

    return Text(name,
        style: textTheme.subtitle2, overflow: TextOverflow.ellipsis);
  }
}
