import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

class ImageViewerPage extends StatefulWidget {
  final Media media;
  final File image;

  ImageViewerPage(this.media, this.image);

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  AppBar _appBar() {
    return AppBar(
      title: Text(widget.media.name),
      centerTitle: true,
      automaticallyImplyLeading: true,
    );
  }

  Widget _body() {
    return Center(
      child: FittedBox(
        child: _viewer(),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _viewer() {
    return Image.file(widget.image);
  }
}
