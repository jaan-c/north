import 'dart:async';

import 'package:flutter/material.dart';

typedef SubmitPasswordCallback = FutureOr<void> Function(String password);

/// A page for accepting a password from user.
class PasswordPage extends StatefulWidget {
  final String title;
  final String loadingDescription;
  final SubmitPasswordCallback onSubmitPassword;

  PasswordPage(
      {@required this.title,
      @required this.loadingDescription,
      this.onSubmitPassword});

  @override
  _PasswordPageState createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final passwordController = TextEditingController();
  var isPasswordObscured = true;
  var isPasswordValid = false;
  var isSubmitting = false;

  @override
  void initState() {
    super.initState();
    passwordController
        .addListener(() => isPasswordValid = passwordController.text.isEmpty);
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _body(context)),
      floatingActionButton: isPasswordValid ? _submitFab() : null,
    );
  }

  Widget _body(BuildContext context) {
    return Center(
      child: Padding(
        child: Column(
          children: [
            _titleText(context),
            SizedBox(height: 32),
            if (isSubmitting)
              _loadingIndicator(context)
            else
              _passwordField(context),
          ],
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _titleText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(widget.title, style: textTheme.headline5);
  }

  Widget _loadingIndicator(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        LinearProgressIndicator(),
        SizedBox(height: 8),
        Text(widget.loadingDescription, style: textTheme.subtitle1),
      ],
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
    );
  }

  Widget _passwordField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: passwordController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(isPasswordObscured
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded),
          onPressed: _toggleObscurePassword,
        ),
        border: OutlineInputBorder(),
      ),
      obscureText: isPasswordObscured,
      autofocus: true,
      autocorrect: false,
    );
  }

  Widget _submitFab() {
    return FloatingActionButton(
      child: Icon(Icons.check),
      onPressed: _submitPassword,
    );
  }

  void _toggleObscurePassword() {
    setState(() => isPasswordObscured = !isPasswordObscured);
  }

  Future<void> _submitPassword() async {
    final password = passwordController.text;
    setState(() => isSubmitting = true);
    await widget.onSubmitPassword?.call(password);
    setState(() => isSubmitting = false);
  }
}
