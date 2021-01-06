import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'authentication_model.dart';
import 'password_page.dart';

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthenticationModel>();

    switch (auth.status) {
      case AuthenticationStatus.unconfigured:
        return _setupAuthenticationPage(context);
        break;
      case AuthenticationStatus.close:
        return _authenticationPage(context);
        break;
      case AuthenticationStatus.open:
        return SizedBox.shrink();
        break;
      default:
        throw StateError('Unhandled state ${auth.status}');
    }
  }

  Widget _setupAuthenticationPage(BuildContext context) {
    final auth = context.watch<AuthenticationModel>();

    return PasswordPage(
      title: 'Set Password',
      loadingDescription: 'Setting password and unlocking gallery',
      onSubmitPassword: (password) async {
        await auth.setup(password);
        await auth.authenticate(password);
      },
    );
  }

  Widget _authenticationPage(BuildContext context) {
    final auth = context.watch<AuthenticationModel>();

    return PasswordPage(
      title: 'Enter Password',
      loadingDescription: 'Unlocking gallery',
      onSubmitPassword: (password) async {
        await auth.authenticate(password);
        if (auth.status != AuthenticationStatus.open) {
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
