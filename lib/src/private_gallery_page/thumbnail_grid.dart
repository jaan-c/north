import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ThumbnailGrid extends StatelessWidget {
  final IndexedWidgetBuilder builder;
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  ThumbnailGrid(
      {@required this.builder,
      @required this.itemCount,
      this.crossAxisCount = 2,
      this.mainAxisSpacing = 0,
      this.crossAxisSpacing = 0});

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      itemBuilder: builder,
      staggeredTileBuilder: (_) => StaggeredTile.fit(1),
      itemCount: itemCount,
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      shrinkWrap: true,
    );
  }
}
