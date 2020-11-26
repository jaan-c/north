import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:north/app_preferences.dart';
import 'package:north/src/crypto/password.dart';
import 'package:north/src/widgets/private_gallery_section.dart';

import 'set_password_section.dart';
import 'verify_password_section.dart';

enum PrivateGalleryState { unconfigured, close, open }

class PrivateGalleryScreen extends StatefulWidget {
  @override
  _PrivateGalleryScreenState createState() => _PrivateGalleryScreenState();
}

class _PrivateGalleryScreenState extends State<PrivateGalleryScreen> {
  final prefs = AppPreferences.getInstance();

  Future<PrivateGalleryState> futureState;
  Future<Uint8List> futureKey;

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
            return _privateGallerySection();
          default:
            throw StateError('Unhandled state: ${snapshot.data}');
        }
      },
    );
  }

  Widget _setPasswordSection() {
    return SetPasswordSection(
      onDone: () => setState(() {
        futureState = _determineState();
      }),
    );
  }

  Widget _verifyPasswordSection() {
    return VerifyPasswordSection(onSubmitPassword: _computeKey);
  }

  Future<void> _computeKey(String password) async {
    final salt = await prefs.getSalt();

    setState(() {
      futureKey = deriveKey(password, salt);
      futureState = _determineState();
    });
  }

  Widget _privateGallerySection() {
    return FutureBuilder(
      future: futureKey,
      builder: (_, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to compute key: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return LinearProgressIndicator();
        }

        return PrivateGallerySection(PrivateGallery(snapshot.data));
      },
    );
  }

  Future<PrivateGalleryState> _determineState() async {
    final passwordHash = await prefs.getPasswordHash();
    if (passwordHash.isEmpty) {
      return PrivateGalleryState.unconfigured;
    }

    if (futureKey == null) {
      return PrivateGalleryState.close;
    } else {
      return PrivateGalleryState.open;
    }
  }
}
