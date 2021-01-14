import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';

import 'password_page.dart';

typedef SubmitKeyCallback = void Function(Uint8List key);

class AuthenticationPage extends StatefulWidget {
  final SubmitKeyCallback onSubmitKey;

  AuthenticationPage({this.onSubmitKey});

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  Future<_AuthenticationPageModel> futureAuth;

  @override
  void initState() {
    super.initState();
    futureAuth = _AuthenticationPageModel.instantiate();
  }

  @override
  void dispose() {
    futureAuth.then((a) => a.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureAuth,
      builder: (context, AsyncSnapshot<_AuthenticationPageModel> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        switch (snapshot.data.status) {
          case _AuthenticationStatus.unconfigured:
            return _setupAuthenticationPage(context);
            break;
          case _AuthenticationStatus.close:
            return _authenticationPage(context);
            break;
          case _AuthenticationStatus.open:
            return SizedBox.shrink();
            break;
          default:
            throw StateError('Unhandled state ${snapshot.data.status}');
        }
      },
    );
  }

  Widget _setupAuthenticationPage(BuildContext context) {
    return FutureBuilder(
      future: futureAuth,
      builder: (context, AsyncSnapshot<_AuthenticationPageModel> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return PasswordPage(
          title: 'Set Password',
          loadingDescription: 'Setting password and unlocking gallery',
          onSubmitPassword: (password) async {
            await snapshot.data.setup(password);
            await snapshot.data.authenticate(password);
            widget.onSubmitKey?.call(snapshot.data.key);
          },
        );
      },
    );
  }

  Widget _authenticationPage(BuildContext context) {
    return FutureBuilder(
      future: futureAuth,
      builder: (context, AsyncSnapshot<_AuthenticationPageModel> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return PasswordPage(
          title: 'Enter Password',
          loadingDescription: 'Unlocking gallery',
          onSubmitPassword: (password) async {
            await snapshot.data.authenticate(password);
            if (snapshot.data.status == _AuthenticationStatus.open) {
              widget.onSubmitKey?.call(snapshot.data.key);
            } else {
              _showSnackBar(context, 'Wrong password');
            }
          },
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

enum _AuthenticationStatus { unconfigured, close, open }

class _AuthenticationPageModel with ChangeNotifier {
  static Future<_AuthenticationPageModel> instantiate() async {
    final prefs = await AppPreferences.instantiate();

    _AuthenticationStatus status;
    if (prefs.passwordHash.isEmpty && prefs.salt.isEmpty) {
      status = _AuthenticationStatus.unconfigured;
    } else {
      status = _AuthenticationStatus.close;
    }

    return _AuthenticationPageModel._internal(prefs, status);
  }

  final AppPreferences _prefs;

  _AuthenticationStatus get status => _status;
  Uint8List get key => _key ?? (throw StateError('key is null.'));

  Uint8List _key;
  _AuthenticationStatus _status;

  _AuthenticationPageModel._internal(
      this._prefs, _AuthenticationStatus initialStatus)
      : _status = initialStatus;

  Future<void> setup(String password) async {
    final passwordHash = await derivePasswordHash(password);
    final salt = generateSalt();

    await _prefs.setPasswordHash(passwordHash);
    await _prefs.setSalt(salt);

    _key = Uint8List.fromList([]);
    _status = _AuthenticationStatus.close;
    notifyListeners();
  }

  Future<void> authenticate(String password) async {
    if (status == _AuthenticationStatus.unconfigured) {
      throw StateError(
          'Trying to authenticate while authentication status is unconfigured.');
    } else if (status == _AuthenticationStatus.open) {
      return;
    }

    if (await verifyPassword(password, _prefs.passwordHash)) {
      _key = await deriveKey(password, _prefs.salt);
      _status = _AuthenticationStatus.open;
      notifyListeners();
    }
  }
}
