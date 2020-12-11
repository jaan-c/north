import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ThumbnailGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;

  ThumbnailGrid({this.children = const [], this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      itemBuilder: (_, ix) => children[ix],
      staggeredTileBuilder: (_) => StaggeredTile.fit(1),
      itemCount: children.length,
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
    );
  }
}
