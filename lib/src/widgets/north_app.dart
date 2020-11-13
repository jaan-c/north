import 'package:flutter/material.dart';
import 'package:north/src/widgets/password_screen.dart';

class NorthApp extends StatefulWidget {
  @override
  _NorthAppState createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PasswordScreen(
        onCheckPassword: (password) => password == 'mitlof',
        onSubmitPassword: (password) => debugPrint('Correct password!'),
      ),
    );
  }
}
