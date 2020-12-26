import 'package:flutter/material.dart';

class PromptDialog extends StatelessWidget {
  final String title;
  final String content;
  final String positiveButtonText;
  final VoidCallback onPositivePressed;

  PromptDialog(
      {@required this.title,
      @required this.content,
      @required this.positiveButtonText,
      this.onPositivePressed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(positiveButtonText),
          onPressed: () {
            onPositivePressed();
            Navigator.pop(context);
          },
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
