import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

typedef ThumbnailLoader = Future<File> Function();
typedef ThumbnailTapCallback = void Function();

class ThumbnailData {
  final String name;
  final int count;
  final ThumbnailLoader loader;
  final ThumbnailTapCallback onTap;

  ThumbnailData(
      {@required this.name, @required this.loader, this.count, this.onTap});

  Future<File> loadThumbnail() async {
    return loader();
  }
}

class ThumbnailGrid extends StatelessWidget {
  final List<ThumbnailData> datas;
  final EdgeInsetsGeometry padding;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double thumbnailBorderRadius;
  final bool showThumbnailName;

  ThumbnailGrid(this.datas,
      {this.padding = const EdgeInsets.all(0),
      this.crossAxisCount = 2,
      this.mainAxisSpacing = 0,
      this.crossAxisSpacing = 0,
      this.thumbnailBorderRadius = 0,
      this.showThumbnailName = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: StaggeredGridView.countBuilder(
        itemBuilder: (_, ix) => _ThumbnailTile(
          datas[ix],
          borderRadius: thumbnailBorderRadius,
          showName: showThumbnailName,
        ),
        staggeredTileBuilder: (_) => StaggeredTile.fit(1),
        itemCount: datas.length,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        shrinkWrap: true,
      ),
      padding: padding,
    );
  }
}

class _ThumbnailTile extends StatefulWidget {
  final ThumbnailData data;
  final double borderRadius;
  final bool showName;

  _ThumbnailTile(this.data, {this.borderRadius = 0, this.showName = true});

  @override
  _ThumbnailTileState createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends State<_ThumbnailTile> {
  Future<File> futureThumbnail;

  @override
  void initState() {
    super.initState();
    futureThumbnail = widget.data.loadThumbnail();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Column(children: [
        _thumbnailImageContainer(child: _thumbnailImage()),
        if (widget.showName) ...[
          SizedBox(height: 4),
          _thumbnailName(context),
        ]
      ]),
      onTap: widget.data.onTap,
    );
  }

  Widget _thumbnailImageContainer({@required Widget child}) {
    return ClipRRect(
      child: AspectRatio(
        aspectRatio: 1 / 1,
        child: child,
      ),
      borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
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
        Text(
          widget.data.name,
          style: textTheme.subtitle2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.data.count != null)
          Text(' (${widget.data.count})', style: textTheme.subtitle2),
      ],
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
    );
  }
}
