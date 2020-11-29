import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:north/private_gallery.dart';
import 'package:north/src/private_gallery/loader.dart';

class ThumbnailData {
  final String name;
  final ThumbnailLoader loader;

  ThumbnailData({@required this.name, @required this.loader});

  ThumbnailData.fromAlbum(Album album)
      : this(name: album.name, loader: album.thumbnailLoader);

  ThumbnailData.fromMedia(Media media)
      : this(name: media.name, loader: media.thumbnailLoader);
}

class ThumbnailGrid extends StatelessWidget {
  final List<ThumbnailData> datas;

  ThumbnailGrid(this.datas);

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      itemBuilder: (_, ix) => _ThumbnailTile(datas[ix]),
      staggeredTileBuilder: (_) => StaggeredTile.fit(1),
      itemCount: datas.length,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
    );
  }
}

class _ThumbnailTile extends StatefulWidget {
  final ThumbnailData data;

  _ThumbnailTile(this.data);

  @override
  _ThumbnailTileState createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends State<_ThumbnailTile> {
  Future<File> futureThumbnail;

  @override
  void initState() {
    futureThumbnail = widget.data.loader.load();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _thumbnailImageContainer(child: _thumbnailImage()),
      SizedBox(height: 4),
      _thumbnailName(context)
    ]);
  }

  Widget _thumbnailImageContainer({@required Widget child}) {
    return ClipRRect(
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: child,
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
  }

  Widget _thumbnailImage() {
    return FutureBuilder(
      future: futureThumbnail,
      builder: (context, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasError) {
          final textTheme = Theme.of(context).textTheme;
          return Center(
            child: Text(
              'No thumbnail',
              style: textTheme.subtitle2,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.hasData) {
          return FittedBox(child: Image.file(snapshot.data));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _thumbnailName(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Text(widget.data.name,
        style: textTheme.subtitle2, overflow: TextOverflow.ellipsis);
  }
}
