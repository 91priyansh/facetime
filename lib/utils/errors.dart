import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Errors {
  static String defaultErrorMessage = "Unwanted error occurred";
  static Widget getErrorPage() {
    return Scaffold();
  }

  //to show error dialog
  static void showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
              content: Text(errorMessage),
              actions: [
                CupertinoButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Okay"),
                )
              ],
            ));
  }
}
