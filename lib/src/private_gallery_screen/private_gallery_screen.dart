import 'package:flutter/material.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';
import 'package:north/app_preferences.dart';

import 'gallery_pages_navigator.dart';
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
  void dispose() {
    futureGallery.then((g) => g.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            return _setupAuthenticaitonPage();
          case PrivateGalleryState.close:
            return _authenticationPage();
          case PrivateGalleryState.open:
            return _galleryPageNavigator();
          default:
            throw StateError('Unhandled state: ${snapshot.data}');
        }
      },
    );
  }

  Widget _setupAuthenticaitonPage() {
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

  Widget _galleryPageNavigator() {
    return FutureBuilder(
      future: futureGallery,
      builder: (context, AsyncSnapshot<PrivateGallery> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to compute key: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return _unlockingGalleryProgressPage(context);
        }

        if (snapshot.hasData) {
          return GalleryPagesNavigator(snapshot.data);
        } else {
          return LinearProgressIndicator();
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
