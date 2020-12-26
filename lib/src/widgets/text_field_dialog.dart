import 'package:flutter/material.dart';

typedef CheckTextCallback = bool Function(String text);
typedef SubmitTextCallback = void Function(String text);

class TextFieldDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String positiveTextButton;
  final CheckTextCallback onCheckText;
  final SubmitTextCallback onSubmitText;

  TextFieldDialog(
      {@required this.title,
      @required this.initialText,
      @required this.positiveTextButton,
      @required this.onCheckText,
      @required this.onSubmitText});

  @override
  _TextFieldDialogState createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<TextFieldDialog> {
  TextEditingController fieldController;
  var isTextValid = false;

  @override
  void initState() {
    super.initState();
    fieldController = TextEditingController(text: widget.initialText);
    fieldController.addListener(_setIsTextValid);
  }

  void _setIsTextValid() {
    setState(() => isTextValid = widget.onCheckText(fieldController.text));
  }

  @override
  void dispose() {
    fieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _textField(context),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text(widget.positiveTextButton),
          onPressed: isTextValid
              ? () {
                  widget.onSubmitText(fieldController.text);
                  Navigator.pop(context);
                }
              : null,
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _textField(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: fieldController,
      style: textTheme.subtitle1,
      decoration: InputDecoration(border: OutlineInputBorder()),
      autofocus: true,
      autocorrect: true,
    );
  }
}
