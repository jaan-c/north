import 'dart:async';

import 'package:flutter/material.dart';

typedef PositivePressedCallback = FutureOr<void> Function();

/// A prompt dialog that shows an indefinite progress indicator while running an
/// arbitrary operation.
class OperationPromptDialog extends StatefulWidget {
  final String title;
  final String description;
  final String positiveButtonText;
  final String operationDescription;
  final VoidCallback onPositivePressed;

  OperationPromptDialog(
      {@required this.title,
      @required this.description,
      @required this.positiveButtonText,
      @required this.operationDescription,
      @required this.onPositivePressed});

  @override
  _OperationPromptDialogState createState() => _OperationPromptDialogState();
}

class _OperationPromptDialogState extends State<OperationPromptDialog> {
  var isRunning = false;

  @override
  Widget build(BuildContext context) {
    return !isRunning ? _promptDialog(context) : _progressDialog(context);
  }

  Widget _promptDialog(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Text(widget.description),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(widget.positiveButtonText),
          onPressed: () async {
            await _runOperation();
            Navigator.pop(context);
          },
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Future<void> _runOperation() async {
    setState(() => isRunning = true);
    await widget.onPositivePressed();
  }

  Widget _progressDialog(BuildContext context) {
    return AlertDialog(
      content: Column(
        children: [
          LinearProgressIndicator(),
          Text(widget.operationDescription)
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
