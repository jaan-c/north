import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'gallery_model.dart';

class GalleryProvider extends StatelessWidget {
  final Uint8List galleryKey;
  final WidgetBuilder builder;

  GalleryProvider(this.galleryKey, {this.builder});

  @override
  Widget build(BuildContext context) {
    return _FutureChangeNotifierProvider(
      create: () => GalleryModel.instantiate(galleryKey),
      builder: builder,
    );
  }
}

class _FutureChangeNotifierProvider<T extends ChangeNotifier>
    extends StatefulWidget {
  final Future<T> Function() create;
  final WidgetBuilder builder;

  _FutureChangeNotifierProvider(
      {@required this.create, @required this.builder});

  @override
  _FutureChangeNotifierProviderState<T> createState() =>
      _FutureChangeNotifierProviderState<T>();
}

class _FutureChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<_FutureChangeNotifierProvider<T>> {
  Future<T> futureChangeNotifier;

  @override
  void initState() {
    super.initState();
    futureChangeNotifier = widget.create();
  }

  @override
  void dispose() {
    futureChangeNotifier.then((cn) => cn.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureChangeNotifier,
      builder: (context, AsyncSnapshot<T> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (snapshot.hasData) {
          return ChangeNotifierProvider.value(
            value: snapshot.data,
            builder: (context, _) => widget.builder(context),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
