import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'authentication_model.dart';
import 'gallery_model.dart';

class ModelsProvider extends StatelessWidget {
  final WidgetBuilder builder;

  ModelsProvider({this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureChangeNotifierProvider(
      create: AuthenticationModel.instantiate,
      builder: (context) {
        final auth = context.watch<AuthenticationModel>();

        if (auth.status == AuthenticationStatus.open) {
          return FutureChangeNotifierProvider(
            create: () => GalleryModel.instantiate(auth.key),
            builder: builder,
          );
        } else {
          return builder(context);
        }
      },
    );
  }
}

class FutureChangeNotifierProvider<T extends ChangeNotifier>
    extends StatefulWidget {
  final Future<T> Function() create;
  final WidgetBuilder builder;

  FutureChangeNotifierProvider({@required this.create, @required this.builder});

  @override
  _FutureChangeNotifierProviderState<T> createState() =>
      _FutureChangeNotifierProviderState<T>();
}

class _FutureChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<FutureChangeNotifierProvider<T>> {
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
