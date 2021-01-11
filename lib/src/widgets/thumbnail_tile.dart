import 'dart:io';

import 'package:flutter/material.dart';

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

typedef ThumbnailLoader = Future<File> Function();

class _ThumbnailTileState extends State<ThumbnailTile> {
  Future<File> futureThumbnail;

  @override
  void initState() {
    super.initState();
    futureThumbnail = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _thumbnailEmbellishment(
          context: context,
          child: _thumbnailImage(),
        ),
        if (widget.name.isNotEmpty) SizedBox(height: 8),
        _thumbnailName(context),
      ],
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  Widget _thumbnailEmbellishment(
      {@required BuildContext context, @required Widget child}) {
    if (widget.mode == ThumbnailTileMode.normal) {
      return child;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Padding(
          child: child,
          padding: widget.mode == ThumbnailTileMode.unselected
              ? EdgeInsets.zero
              : EdgeInsets.all(16),
        ),
        Padding(
          child: widget.mode == ThumbnailTileMode.unselected
              ? Icon(
                  Icons.radio_button_off_rounded,
                  color: colorScheme.surface,
                )
              : Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
          padding: EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _thumbnailImage() {
    return FutureBuilder(
      future: futureThumbnail,
      builder: (_, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load thumbnail: ${snapshot.error}');
        }

        return AspectRatio(
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.grey,
              image: snapshot.hasData
                  ? DecorationImage(
                      image: FileImage(snapshot.data),
                      fit: BoxFit.cover,
                    )
                  : null,
              borderRadius: widget.borderRadius,
            ),
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              borderRadius: widget.borderRadius,
            ),
          ),
          aspectRatio: 1 / 1,
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
          style: textTheme.subtitle1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.count > 0)
          Text(' (${widget.count})', style: textTheme.subtitle1),
      ],
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
    );
  }
}
