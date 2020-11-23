import 'package:flutter/material.dart';
import 'package:north/shared_preferences.dart';
import 'package:north/src/crypto/password.dart';

typedef SubmitPasswordCallback = void Function(String password);

class VerifyPasswordScreen extends StatefulWidget {
  final SubmitPasswordCallback onSubmitPassword;

  VerifyPasswordScreen({@required this.onSubmitPassword});

  @override
  _VerifyPasswordScreenState createState() => _VerifyPasswordScreenState();
}

class _VerifyPasswordScreenState extends State<VerifyPasswordScreen> {
  final passwordController = TextEditingController(text: '');
  final prefs = SharedPreferences.getInstance();

  var isCheckingPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _body(context)),
      floatingActionButton: _submitFab(context),
    );
  }

  Widget _body(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        child: Column(
          children: [
            Text('Enter Password', style: textTheme.headline5),
            SizedBox(height: 16),
            _passwordField(context),
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: passwordController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(border: OutlineInputBorder()),
      obscureText: true,
      autofocus: true,
      autocorrect: false,
    );
  }

  Widget _submitFab(BuildContext context) {
    return FloatingActionButton.extended(
      icon: Icon(Icons.check),
      label: Text('Submit'),
      onPressed: isCheckingPassword ? null : () => _onSubmitPassword(context),
      disabledElevation: 0,
    );
  }

  void _onSubmitPassword(BuildContext context) async {
    final password = passwordController.text;

    if (password.isEmpty) {
      _showSnackBar(context, 'Empty password.');
      return;
    }

    _showSnackBar(context, 'Checking password.');
    isCheckingPassword = true;

    if (verifyPasswordWithHash(password, await prefs.getPasswordHash())) {
      widget.onSubmitPassword(password);
    } else {
      _showSnackBar(context, 'Wrong password.');
    }

    isCheckingPassword = false;
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    final snackBar =
        SnackBar(content: Text(message), duration: Duration(seconds: 1));
    messenger.showSnackBar(snackBar);
  }
}
