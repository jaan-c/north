import 'package:flutter/material.dart';

import 'operation_queue_controller.dart';

class OperationQueueDialog extends StatefulWidget {
  final String title;
  final OperationQueueController queueController;

  OperationQueueDialog({@required this.title, @required this.queueController});

  @override
  _OperationQueueDialogState createState() => _OperationQueueDialogState();
}

class _OperationQueueDialogState extends State<OperationQueueDialog> {
  @override
  void initState() {
    super.initState();
    widget.queueController.addListener(() => setState(() {}));
    widget.queueController.start();
  }

  @override
  void dispose() {
    widget.queueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.queueController.isDone) {
      Future.delayed(Duration.zero, () => Navigator.pop(context));
    }

    return AlertDialog(
      title: Text(widget.title),
      content: LinearProgressIndicator(value: widget.queueController.progress),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () {
            widget.queueController.cancel();
            Navigator.pop(context);
          },
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
