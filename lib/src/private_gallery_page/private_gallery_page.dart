import 'package:flutter/material.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';
import 'package:north/app_preferences.dart';

import 'album_listing_page.dart';
import 'setup_authentication_page.dart';
import 'authentication_page.dart';

enum _PrivateGalleryState { unconfigured, close, open }

class PrivateGalleryPage extends StatefulWidget {
  @override
  _PrivateGalleryPageState createState() => _PrivateGalleryPageState();
}

class _PrivateGalleryPageState extends State<PrivateGalleryPage> {
  final prefs = AppPreferences.getInstance();

  Future<_PrivateGalleryState> futureState;
  Future<PrivateGallery> futureGallery;

  @override
  void initState() {
    super.initState();
    futureState = _determineState();
  }

  @override
  void dispose() {
    futureGallery.then((g) => g.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureState,
      builder: (_, AsyncSnapshot<_PrivateGalleryState> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to determine state: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }

        switch (snapshot.data) {
          case _PrivateGalleryState.unconfigured:
            return _setupAuthenticationPage();
          case _PrivateGalleryState.close:
            return _authenticationPage();
          case _PrivateGalleryState.open:
            return _albumListingPage();
          default:
            throw StateError('Unhandled state: ${snapshot.data}');
        }
      },
    );
  }

  Widget _setupAuthenticationPage() {
    return SetupAuthenticationPage(onDone: _instantiateGallery);
  }

  Widget _authenticationPage() {
    return AuthenticationPage(onSubmitPassword: _instantiateGallery);
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

  Widget _albumListingPage() {
    return FutureBuilder(
      future: futureGallery,
      builder: (context, AsyncSnapshot<PrivateGallery> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to compute key: ${snapshot.error}');
        }

        if (snapshot.hasData) {
          return AlbumListingPage(snapshot.data);
        } else {
          return _unlockingGalleryProgressPage(context);
        }
      },
    );
  }

  Widget _unlockingGalleryProgressPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            child: Column(
              children: [
                LinearProgressIndicator(),
                SizedBox(height: 8),
                Text(
                  'Unlocking Private Gallery',
                  style: textTheme.subtitle2,
                ),
              ],
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  Future<_PrivateGalleryState> _determineState() async {
    final passwordHash = await prefs.getPasswordHash();
    if (passwordHash.isEmpty) {
      return _PrivateGalleryState.unconfigured;
    }

    return futureGallery == null
        ? _PrivateGalleryState.close
        : _PrivateGalleryState.open;
  }
}
