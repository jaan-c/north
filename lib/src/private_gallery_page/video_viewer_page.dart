import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:video_player/video_player.dart';

class VideoViewerPage extends StatefulWidget {
  final Media media;
  final File video;

  VideoViewerPage(this.media, this.video);

  @override
  _VideoViewerPageState createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends State<VideoViewerPage> {
  VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.video);
  }

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
    return VideoPlayer(controller);
  }
}
