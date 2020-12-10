import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

typedef IndexedCallback = void Function(int index);
typedef ThumbnailLoader = Future<File> Function();

class ThumbnailData {
  final String name;
  final int count;
  final ThumbnailLoader loader;

  ThumbnailData({@required this.name, @required this.loader, this.count});
}

class ThumbnailGrid extends StatelessWidget {
  final List<ThumbnailData> datas;
  final List<int> selectedIndices;
  final EdgeInsetsGeometry padding;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final BorderRadius thumbnailBorderRadius;
  final bool showThumbnailName;
  final IndexedCallback onThumbnailTap;
  final IndexedCallback onThumbnailLongPress;

  ThumbnailGrid(this.datas,
      {this.selectedIndices = const [],
      this.padding = const EdgeInsets.all(0),
      this.crossAxisCount = 2,
      this.mainAxisSpacing = 0,
      this.crossAxisSpacing = 0,
      this.thumbnailBorderRadius = BorderRadius.zero,
      this.showThumbnailName = true,
      this.onThumbnailTap,
      this.onThumbnailLongPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      child: StaggeredGridView.countBuilder(
        itemBuilder: (_, ix) => _thumbnailTile(ix),
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

  Widget _thumbnailTile(int index) {
    final data = datas[index];
    ThumbnailTileMode mode;
    if (selectedIndices.isEmpty) {
      mode = ThumbnailTileMode.normal;
    } else {
      mode = selectedIndices.contains(index)
          ? ThumbnailTileMode.selected
          : ThumbnailTileMode.unselected;
    }

    return ThumbnailTile(
      loader: data.loader,
      name: data.name,
      count: data.count ?? 0,
      mode: mode,
      borderRadius: thumbnailBorderRadius,
      onTap: () => onThumbnailTap(index),
      onLongPress: () => onThumbnailLongPress(index),
    );
  }
}

enum ThumbnailTileMode { normal, unselected, selected }

class ThumbnailTile extends StatefulWidget {
  final ThumbnailLoader loader;
  final String name;
  final int count;
  final ThumbnailTileMode mode;
  final BorderRadius borderRadius;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  ThumbnailTile(
      {@required this.loader,
      this.name = '',
      this.count = 0,
      this.mode = ThumbnailTileMode.normal,
      this.borderRadius = BorderRadius.zero,
      this.onTap,
      this.onLongPress});

  @override
  _ThumbnailTileState createState() => _ThumbnailTileState();
}

class _ThumbnailTileState extends State<ThumbnailTile> {
  Future<File> futureThumbnail;

  @override
  void initState() {
    super.initState();
    futureThumbnail = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Column(
        children: [
          _thumbnailEmbellishment(
            child: _thumbnailContainer(
              child: _thumbnailImage(),
            ),
          ),
          if (widget.name.isNotEmpty) SizedBox(height: 8),
          _thumbnailName(context),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  Widget _thumbnailEmbellishment({@required Widget child}) {
    if (widget.mode == ThumbnailTileMode.normal) {
      return child;
    }

    return Stack(
      children: [
        Expanded(
          child: Padding(
            child: child,
            padding: widget.mode == ThumbnailTileMode.unselected
                ? EdgeInsets.zero
                : EdgeInsets.all(16),
          ),
        ),
        Padding(
          child: Icon(widget.mode == ThumbnailTileMode.unselected
              ? Icons.radio_button_off_rounded
              : Icons.check_circle_rounded),
          padding: EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _thumbnailContainer({@required Widget child}) {
    return ClipRRect(
      child: AspectRatio(
        child: child,
        aspectRatio: 1 / 1,
      ),
      borderRadius: widget.borderRadius,
    );
  }

  Widget _thumbnailImage() {
    return FutureBuilder(
      future: futureThumbnail,
      builder: (_, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load thumbnail: ${snapshot.error}');
        }

        return FittedBox(
          child: snapshot.hasData
              ? Image.file(snapshot.data)
              : Container(color: Colors.grey),
        );
      },
    );
  }

  Widget _thumbnailName(BuildContext context) {
    if (widget.name.isEmpty) {
      return SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          widget.name,
          style: textTheme.subtitle2,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.count > 0)
          Text(' (${widget.count})', style: textTheme.subtitle2),
      ],
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
    );
  }
}
