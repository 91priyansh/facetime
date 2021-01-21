import 'package:flutter/material.dart';

class CustomException implements Exception {
  String errorMessage;

  CustomException({@required this.errorMessage});

  @override
  String toString() {
    return "$errorMessage ):";
  }
}
