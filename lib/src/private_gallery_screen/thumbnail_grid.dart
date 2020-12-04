import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

typedef ThumbnailLoader = Future<File> Function();

class ThumbnailData {
  final String name;
  final int count;
  final ThumbnailLoader loader;

  ThumbnailData({@required this.name, @required this.loader, this.count});

  Future<File> loadThumbnail() async {
    return loader();
  }
}

class ThumbnailGrid extends StatelessWidget {
  final List<ThumbnailData> datas;

  ThumbnailGrid(this.datas);

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      itemBuilder: (_, ix) => ThumbnailTile(datas[ix]),
      staggeredTileBuilder: (_) => StaggeredTile.fit(1),
      itemCount: datas.length,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
    );
  }
}

class ThumbnailTile extends StatefulWidget {
  final ThumbnailData data;

  ThumbnailTile(this.data);

  @override
  ThumbnailTileState createState() => ThumbnailTileState();
}

class ThumbnailTileState extends State<ThumbnailTile> {
  Future<File> futureThumbnail;

  @override
  void initState() {
    super.initState();
    futureThumbnail = widget.data.loadThumbnail();
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
          throw StateError('Failed to load thumbnail: ${snapshot.error}');
        }

        return FittedBox(
            child: snapshot.hasData
                ? Image.file(snapshot.data)
                : _thumbnailImagePlaceholder());
      },
    );
  }

  Widget _thumbnailImagePlaceholder() {
    return SizedBox(
      child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
    );
  }

  Widget _thumbnailName(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.data.name,
            style: textTheme.subtitle2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.data.count != null)
          Text('(${widget.data.count})', style: textTheme.subtitle2),
      ],
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.baseline,
    );
  }
}
