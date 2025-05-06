import 'package:flutter/material.dart';

class DialogUtils {
  /// Shows an alert dialog with a title, message, and an OK button.
  ///
  /// This is a utility method to standardize alert dialogs across the app.
  static void showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}