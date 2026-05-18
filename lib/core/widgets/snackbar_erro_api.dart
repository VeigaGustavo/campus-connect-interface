import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:flutter/material.dart';

void showFloatingSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

void showFloatingSnackBarMaybe(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

void showApiErrorSnackBar(BuildContext context, ApiException error) {
  showFloatingSnackBar(context, error.userFacingOrBody);
}
