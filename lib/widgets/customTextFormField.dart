import 'package:flutter/material.dart';

//Custom text form field
class CustomTextFormField extends StatelessWidget {
  final bool obscureText;
  final Function onSaved;
  final Function validator;
  final TextInputType textInputType;
  final String hintText;
  final bool enabled;
  const CustomTextFormField(
      {Key key,
      @required this.obscureText,
      @required this.enabled,
      @required this.onSaved,
      @required this.textInputType,
      @required this.hintText,
      @required this.validator})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.0, vertical: 5.0),
      child: TextFormField(
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: textInputType,
        validator: validator,
        onSaved: onSaved,
        decoration: InputDecoration(hintText: hintText),
      ),
    );
  }
}
