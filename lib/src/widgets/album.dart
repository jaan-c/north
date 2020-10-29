import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AlbumData {
  final String name;
  final File thumbnail;

  AlbumData({@required this.name, @required this.thumbnail});
}

class AlbumGrid extends StatelessWidget {
  final List<AlbumData> datas;

  AlbumGrid({@required this.datas});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: StaggeredGridView.countBuilder(
            itemCount: datas.length,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            itemBuilder: (_, ix) => _AlbumTile(data: datas[ix]),
            staggeredTileBuilder: (_) => StaggeredTile.fit(1)));
  }
}

class _AlbumTile extends StatelessWidget {
  final AlbumData data;

  _AlbumTile({@required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumbnail(data.thumbnail),
        SizedBox(height: 4),
        _buildAlbumName(context, data.name)
      ],
    );
  }

  Widget _buildThumbnail(File thumbnail) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      child: AspectRatio(
          aspectRatio: 1 / 1,
          child: FittedBox(
              child: Image.asset('assets/haskell.png'), fit: BoxFit.cover)),
    );
  }

  Widget _buildAlbumName(BuildContext context, String name) {
    final textTheme = Theme.of(context).textTheme;

    return Text(name,
        style: textTheme.subtitle2, overflow: TextOverflow.ellipsis);
  }
}
