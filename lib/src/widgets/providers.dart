import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:provider/provider.dart';

class Providers extends StatelessWidget {
  final Widget Function(BuildContext, Widget) builder;
  final Widget child;

  Providers({this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return FutureProvider(
      create: (_) => AppPreferences.instantiate(),
      builder: builder,
      child: child,
    );
  }
}
