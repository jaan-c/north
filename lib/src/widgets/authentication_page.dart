import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:north/crypto.dart';
import 'package:provider/provider.dart';

import 'gallery_model.dart';
import 'password_page.dart';

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  _AuthenticationPageModel model;

  @override
  void initState() {
    super.initState();

    model = _AuthenticationPageModel();
    model.addListener(() => setState(() {}));
    model.initialize(context);
  }

  @override
  void dispose() {
    model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!model.isInitialized) {
      return Scaffold();
    }

    switch (model.state) {
      case _AuthenticationPageModelState.unconfigured:
        return _setupAuthenticationPage(context);
        break;
      case _AuthenticationPageModelState.close:
        return _authenticationPage(context);
        break;
      case _AuthenticationPageModelState.open:
        return SizedBox.shrink();
        break;
      default:
        throw StateError('Unhandled state ${model.state}');
    }
  }

  Widget _setupAuthenticationPage(BuildContext context) {
    return PasswordPage(
      title: 'Set Password',
      loadingDescription: 'Setting password and unlocking gallery',
      onSubmitPassword: (password) =>
          model.setupAuthentication(context, password),
    );
  }

  Widget _authenticationPage(BuildContext context) {
    return PasswordPage(
      title: 'Enter Password',
      loadingDescription: 'Unlocking gallery',
      onSubmitPassword: (password) async {
        await model.authenticate(context, password);
        if (model.state != _AuthenticationPageModelState.open) {
          _showSnackBar(context, 'Wrong password');
        }
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

enum _AuthenticationPageModelState { unconfigured, close, open }

class _AuthenticationPageModel with ChangeNotifier {
  bool get isInitialized => _isInitialized;
  _AuthenticationPageModelState get state => _state;

  var _isInitialized = false;
  var _state = _AuthenticationPageModelState.unconfigured;

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) {
      return;
    }

    final prefs = context.read<AppPreferences>();
    if ((await prefs.passwordHash).isEmpty) {
      _state = _AuthenticationPageModelState.unconfigured;
    } else {
      _state = _AuthenticationPageModelState.close;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setupAuthentication(
      BuildContext context, String password) async {
    final prefs = context.read<AppPreferences>();
    final gallery = context.read<GalleryModel>();

    final hash = await derivePasswordHash(password);
    final salt = await prefs.salt;
    await prefs.setPasswordHash(hash);
    await prefs.setSalt(salt);

    _state = _AuthenticationPageModelState.open;
    final key = await deriveKey(password, salt);
    await gallery.open(key);

    notifyListeners();
  }

  Future<void> authenticate(BuildContext context, String password) async {
    final prefs = context.read<AppPreferences>();
    final gallery = context.read<GalleryModel>();

    final hash = await prefs.passwordHash;
    if (await verifyPassword(password, hash)) {
      final salt = await prefs.salt;
      _state = _AuthenticationPageModelState.open;
      final key = await deriveKey(password, salt);
      await gallery.open(key);

      notifyListeners();
    }
  }
}
