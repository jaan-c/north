import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class ImportMediaDialog extends StatefulWidget {
  @override
  _ImportMediaDialogState createState() => _ImportMediaDialogState();
}

class _ImportMediaDialogState extends State<ImportMediaDialog> {
  var hasPicked = false;
  var medias = <File>[];
  Album destinationAlbum;
  CancellableFuture<void> importOperation;

  @override
  void initState() {
    super.initState();
    openFilePicker();
  }

  Future<void> openFilePicker() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.media, allowMultiple: true);

    if (result != null) {
      setState(() => medias = result.paths.map((p) => File(p)).toList());
    }

    setState(() => hasPicked = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPicked) {
      return SizedBox.shrink();
    } else if (hasPicked && medias.isEmpty) {
      Future.delayed(Duration.zero, () => Navigator.pop(context));
      return SizedBox.shrink();
    }

    if (destinationAlbum == null) {
      return AlbumPickerDialog(
        onAlbumPressed: (album) async {
          setState(() => destinationAlbum = album);
          await _importMedias(context);
        },
      );
    } else {
      return _progressDialog();
    }
  }

  Widget _progressDialog() {
    return AlertDialog(
      content: Column(
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 8),
          Text('Importing ${medias.length} media'),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: importOperation.cancel,
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Future<void> _importMedias(BuildContext context) async {
    final gallery = context.read<GalleryModel>();

    for (final m in medias) {
      setState(() {
        importOperation =
            gallery.put(Uuid.generate(), destinationAlbum.name, m);
      });

      try {
        await importOperation;
      } on CancelledException {
        break;
      }
    }

    Navigator.pop(context);
  }
}

typedef AlbumPressedCallback = void Function(Album album);

class AlbumPickerDialog extends StatefulWidget {
  final AlbumPressedCallback onAlbumPressed;

  AlbumPickerDialog({this.onAlbumPressed});

  @override
  _AlbumPickerDialogState createState() => _AlbumPickerDialogState();
}

class _AlbumPickerDialogState extends State<AlbumPickerDialog> {
  final thumbnailLoaderQueue = FutureQueue<File>();
  Future<List<Album>> futureAlbums;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gallery = Provider.of<GalleryModel>(context, listen: true);
    futureAlbums = gallery.getAllAlbums();
    thumbnailLoaderQueue.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select album'),
      content: _thumbnailGrid(),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _thumbnailGrid() {
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
          builder: (_, ix) => _thumbnailTile(snapshot.data[ix]),
          itemCount: snapshot.data.length,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        );
      },
    );
  }

  Widget _thumbnailTile(Album album) {
    return ThumbnailTile(
      name: album.name,
      loader: () => thumbnailLoaderQueue.add(
          () => context.read<GalleryModel>().loadAlbumThumbnail(album.name)),
      mode: ThumbnailTileMode.normal,
      borderRadius: BorderRadius.circular(24),
      onTap: () => widget.onAlbumPressed?.call(album),
    );
  }
}
