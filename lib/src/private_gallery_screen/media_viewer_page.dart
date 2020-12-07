import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:north/private_gallery.dart';

import 'image_viewer_page.dart';
import 'video_viewer_page.dart';

class MediaViewerPage extends StatefulWidget {
  final PrivateGallery gallery;
  final Media media;

  MediaViewerPage(this.gallery, this.media);

  @override
  _MediaViewerPageState createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  CancelableFuture<File> futureMediaFile;
  Future<_MediaType> futureMediaType;

  @override
  void initState() {
    super.initState();
    futureMediaFile = widget.gallery.loadMedia(widget.media.id);
    futureMediaType = futureMediaFile.then(_getMediaType);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureMediaFile,
      builder: (context, AsyncSnapshot<File> snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error is CancelledException) {
            return SizedBox.shrink();
          } else {
            throw StateError('Failed to load media: ${snapshot.error}');
          }
        }

        if (snapshot.hasData) {
          return _viewerPage(snapshot.data);
        } else {
          return _loadingPage(context);
        }
      },
    );
  }

  Widget _viewerPage(File mediaFile) {
    return FutureBuilder(
      future: futureMediaType,
      builder: (_, AsyncSnapshot<_MediaType> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to get media type: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        switch (snapshot.data) {
          case _MediaType.image:
            return ImageViewerPage(widget.media, mediaFile);
          case _MediaType.video:
            return VideoViewerPage(widget.media, mediaFile);
          default:
            throw StateError('Unhandled media type: ${snapshot.data}');
        }
      },
    );
  }

  Widget _loadingPage(BuildContext context) {
    return Scaffold(
      appBar: _loadingPageAppBar(context),
      body: _loadingPageBody(context),
    );
  }

  AppBar _loadingPageAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          futureMediaFile.cancel();
          Navigator.pop(context);
        },
      ),
      title: Text(widget.media.name),
      centerTitle: true,
    );
  }

  Widget _loadingPageBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Decrypting media', style: textTheme.subtitle2),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
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
