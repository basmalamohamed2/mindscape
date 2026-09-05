import 'package:flutter/widgets.dart';

class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? signInPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  static FormFieldValidator<String> confirmPassword(
    TextEditingController passwordController,
  ) {
    return (value) {
      if (value == null || value.isEmpty) return 'Confirm your password';
      if (value != passwordController.text) return 'Passwords do not match';
      return null;
    };
  }
}
