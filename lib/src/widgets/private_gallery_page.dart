import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';

import 'album_listing_page.dart';

class PrivateGalleryPage extends StatefulWidget {
  final Uint8List galleryKey;

  PrivateGalleryPage({@required this.galleryKey});

  @override
  _PrivateGalleryPageState createState() => _PrivateGalleryPageState();
}

class _PrivateGalleryPageState extends State<PrivateGalleryPage> {
  Future<PrivateGallery> futureGallery;

  @override
  void initState() {
    super.initState();
    futureGallery = PrivateGallery.instantiate(widget.galleryKey);
  }

  @override
  void dispose() {
    futureGallery.then((gallery) => gallery.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureGallery,
      builder: (_, AsyncSnapshot<PrivateGallery> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (snapshot.hasData) {
          return AlbumListingPage(snapshot.data);
        } else {
          return SizedBox.expand();
        }
      },
    );
  }
}
