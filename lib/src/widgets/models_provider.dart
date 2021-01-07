import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'authentication_model.dart';
import 'gallery_model.dart';

class ModelsProvider extends StatelessWidget {
  final Widget Function(BuildContext, Widget) builder;
  final Widget child;

  ModelsProvider({this.builder, this.child});

  @override
  Widget build(BuildContext context) {
    return FutureProvider(
      create: (_) => AuthenticationModel.instantiate(),
      builder: (context, child) {
        final auth = context.watch<AuthenticationModel>();

        if (auth.status == AuthenticationStatus.open) {
          return FutureProvider(
            create: (_) => GalleryModel.instantiate(auth.key),
            builder: builder,
            child: child,
          );
        } else {
          return builder(context, child);
        }
      },
      child: child,
    );
  }
}
