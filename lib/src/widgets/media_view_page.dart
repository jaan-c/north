import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'gallery_model.dart';
import 'media_view.dart';

class MediaViewPage extends StatefulWidget {
  final Media media;

  MediaViewPage(this.media);

  @override
  _MediaViewPageState createState() => _MediaViewPageState();
}

class _MediaViewPageState extends State<MediaViewPage> {
  Future<File> futureMediaFile;
  Future<_MediaType> futureMediaType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gallery = context.read<GalleryModel>();
    futureMediaFile = gallery.loadMedia(widget.media.id);
    futureMediaType = futureMediaFile.then(_getMediaType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.media.name)),
      body: FutureBuilder(
        future: futureMediaFile,
        builder: (context, AsyncSnapshot<File> snapshot) {
          if (snapshot.hasError) {
            throw snapshot.error;
          }

          if (snapshot.hasData) {
            return _mediaView(snapshot.data);
          } else {
            return _loadingMediaView(context);
          }
        },
      ),
    );
  }

  Widget _loadingMediaView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Decrypting media', style: textTheme.subtitle1),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }

  Widget _mediaView(File mediaFile) {
    return FutureBuilder(
      future: futureMediaType,
      builder: (context, AsyncSnapshot<_MediaType> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.expand();
        }

        switch (snapshot.data) {
          case _MediaType.image:
            return ImageView(image: mediaFile);
          case _MediaType.video:
            return VideoView(video: mediaFile);
          case _MediaType.invalid:
            return _invalidMediaView(context);
          default:
            throw StateError('Unhandled media type ${snapshot.data}');
        }
      },
    );
  }

  Widget _invalidMediaView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        child: Text(
          "'${widget.media.name}' is an invalid media file.",
          style: textTheme.subtitle1,
        ),
        padding: EdgeInsets.all(16),
      ),
    );
  }
}

enum _MediaType { image, video, invalid }

Future<_MediaType> _getMediaType(File media) async {
  final header = await _readMediaHeader(media);
  final mime = lookupMimeType(media.path, headerBytes: header);

  if (mime.startsWith('image')) {
    return _MediaType.image;
  } else if (mime.startsWith('video')) {
    return _MediaType.video;
  } else {
    return _MediaType.invalid;
  }
}

Future<List<int>> _readMediaHeader(File media) async {
  final chunks = await media.openRead(0, defaultMagicNumbersMaxLength).toList();
  final header = chunks.expand((c) => c).toList();
  return header;
}
