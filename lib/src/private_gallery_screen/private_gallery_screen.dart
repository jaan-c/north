import 'package:flutter/material.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';
import 'package:north/app_preferences.dart';

import 'album_thumbnail_grid.dart';
import 'setup_authentication_page.dart';
import 'authentication_page.dart';

enum PrivateGalleryState { unconfigured, close, open }

class PrivateGalleryScreen extends StatefulWidget {
  @override
  _PrivateGalleryScreenState createState() => _PrivateGalleryScreenState();
}

class _PrivateGalleryScreenState extends State<PrivateGalleryScreen> {
  final prefs = AppPreferences.getInstance();

  Future<PrivateGalleryState> futureState;
  Future<PrivateGallery> futureGallery;

  @override
  void initState() {
    super.initState();
    futureState = _determineState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: _body(),
    );
  }

  AppBar _appBar() {
    return AppBar(title: Text('North'), centerTitle: true);
  }

  Widget _body() {
    return FutureBuilder(
      future: futureState,
      builder: (_, AsyncSnapshot<PrivateGalleryState> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to determine state: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }

        switch (snapshot.data) {
          case PrivateGalleryState.unconfigured:
            return _setPasswordSection();
          case PrivateGalleryState.close:
            return _verifyPasswordSection();
          case PrivateGalleryState.open:
            return _albumThumbnailGrid();
          default:
            throw StateError('Unhandled state: ${snapshot.data}');
        }
      },
    );
  }

  Widget _setPasswordSection() {
    return SetPasswordSection(onDone: _instantiateGallery);
  }

  Widget _verifyPasswordSection() {
    return VerifyPasswordSection(onSubmitPassword: _instantiateGallery);
  }

  Future<void> _instantiateGallery(String password) async {
    final salt = await prefs.getSalt();

    setState(() {
      futureGallery = (() async {
        final key = await deriveKey(password, salt);
        return PrivateGallery.instantiate(key);
      })();
      futureState = _determineState();
    });
  }

  Widget _albumThumbnailGrid() {
    return FutureBuilder(
      future: futureGallery,
      builder: (_, AsyncSnapshot<PrivateGallery> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to compute key: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }

        if (snapshot.hasData) {
          return AlbumThumbnailGrid(snapshot.data);
        } else {
          return LinearProgressIndicator();
        }
      },
    );
  }

  Future<PrivateGalleryState> _determineState() async {
    final passwordHash = await prefs.getPasswordHash();
    if (passwordHash.isEmpty) {
      return PrivateGalleryState.unconfigured;
    }

    return futureGallery == null
        ? PrivateGalleryState.close
        : PrivateGalleryState.open;
  }
}
