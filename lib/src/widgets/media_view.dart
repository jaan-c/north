import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ImageView extends StatelessWidget {
  final File image;

  ImageView({@required this.image});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: Image.file(image),
        fit: BoxFit.contain,
      ),
    );
  }
}

class VideoView extends StatefulWidget {
  final File video;

  VideoView({@required this.video});

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(widget.video);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: VideoPlayer(controller),
        fit: BoxFit.contain,
      ),
    );
  }
}
