import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class CopyDialog extends StatelessWidget {
  final List<Media> medias;

  CopyDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(medias: medias, operation: _Operation.copy);
  }
}

class MoveDialog extends StatelessWidget {
  final List<Media> medias;

  MoveDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(medias: medias, operation: _Operation.move);
  }
}

enum _Operation { copy, move }

class _OperationDialog extends StatefulWidget {
  final List<Media> medias;
  final _Operation operation;

  _OperationDialog({@required this.medias, @required this.operation});

  @override
  _OperationDialogState createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  FutureQueue<File> thumbnailLoaderQueue;
  Future<List<Album>> futureAlbums;
  var destinationAlbum = '';

  @override
  void initState() {
    super.initState();

    thumbnailLoaderQueue = FutureQueue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gallery = context.read<GalleryModel>();
    futureAlbums = gallery.getAllAlbums();
    thumbnailLoaderQueue.clear();
  }

  @override
  void dispose() {
    thumbnailLoaderQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (destinationAlbum.isEmpty) {
      return _albumPickerDialog(context);
    } else {
      return _operationProgressDialog(context);
    }
  }

  Widget _albumPickerDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Select album'),
      content: _thumbnailGrid(context),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _thumbnailGrid(BuildContext context) {
    return FutureBuilder(
      future: futureAlbums,
      builder: (_, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return ThumbnailGrid(
          builder: (context, ix) => _thumbnailTile(context, snapshot.data[ix]),
          itemCount: snapshot.data.length,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        );
      },
    );
  }

  Widget _thumbnailTile(BuildContext context, Album album) {
    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => thumbnailLoaderQueue.add(
          () => context.read<GalleryModel>().loadAlbumThumbnail(album.name)),
      mode: ThumbnailTileMode.normal,
      borderRadius: BorderRadius.circular(24),
      onTap: () => _pickDestinationAlbum(context, album.name),
    );
  }

  void _pickDestinationAlbum(BuildContext context, String albumName) {
    setState(() => destinationAlbum = albumName);
    _runOperation(context);
  }

  Future<void> _runOperation(BuildContext context) async {
    final ids = widget.medias.map((m) => m.id).toList();
    final gallery = context.read<GalleryModel>();
    switch (widget.operation) {
      case _Operation.copy:
        await gallery.copyMedias(ids, destinationAlbum);
        break;
      case _Operation.move:
        await gallery.moveMedias(ids, destinationAlbum);
        break;
      default:
        throw StateError('Unhandled operation ${widget.operation}.');
    }

    Navigator.pop(context);
  }

  Widget _operationProgressDialog(BuildContext context) {
    var operationName = '';
    switch (widget.operation) {
      case _Operation.copy:
        operationName = 'Copying';
        break;
      case _Operation.move:
        operationName = 'Moving';
        break;
      default:
        throw StateError('Unhandled operation ${widget.operation}.');
    }

    return AlertDialog(
      title: Text('$operationName media'),
      content: Column(
        children: [
          LinearProgressIndicator(),
          Text(
              '$operationName ${widget.medias.length} media to $destinationAlbum'),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
  }
}
