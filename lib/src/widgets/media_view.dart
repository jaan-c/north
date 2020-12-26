import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

typedef MediaLoaderCallback = Future<File> Function();

class MediaView extends StatefulWidget {
  final MediaLoaderCallback loader;

  MediaView({@required this.loader});

  @override
  _MediaViewState createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  Future<File> futureMediaFile;
  Future<_MediaType> futureMediaType;

  @override
  void initState() {
    super.initState();
    futureMediaFile = widget.loader();
    futureMediaType = futureMediaFile.then((file) => _getMediaType(file));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder()

    return FutureBuilder(
      future: futureMediaType,
      builder: (_, AsyncSnapshot<_MediaType> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.expand();
        }

        switch (snapshot.data) {
          case _MediaType.image:
            return ImageView(image: widget.media);
          case _MediaType.video:
            return VideoView(video: widget.media);
          default:
            throw StateError('Unhandled media type ${snapshot.data}.');
        }
      },
    );
  }
}

class ImageView extends StatelessWidget {
  final File image;

  ImageView({@required this.image});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class VideoView extends StatelessWidget {
  final File video;

  VideoView({@required this.video});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

enum _MediaType { image, video }

Future<_MediaType> _getMediaType(File file) async {
  final header = await _readHeader(file);
  final mime = lookupMimeType(file.path, headerBytes: header);

  if (mime.startsWith('image')) {
    return _MediaType.image;
  } else if (mime.startsWith('video')) {
    return _MediaType.video;
  } else {
    throw StateError('Not a media file ${file.path}: $mime.');
  }
}

Future<List<int>> _readHeader(File file) async {
  return (await file.openRead(0, defaultMagicNumbersMaxLength).toList())
      .expand((chunk) => chunk)
      .toList();
}
