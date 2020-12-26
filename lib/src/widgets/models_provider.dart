import 'package:flutter/material.dart';
import 'package:north/app_preferences.dart';
import 'package:provider/provider.dart';

import 'gallery_model.dart';

class ModelsProvider extends StatelessWidget {
  final Widget Function(BuildContext, Widget) builder;
  final Widget child;

  ModelsProvider({this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider(create: (_) => AppPreferences.instantiate()),
        Provider(create: (_) => GalleryModel()),
      ],
      builder: builder,
      child: child,
    );
  }
}
