import 'package:flutter/material.dart';

class AppDialogs {
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  static Future<void> showWarningDialog(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    VoidCallback? onAction,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAction?.call();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    EdgeInsetsGeometry? margin,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: behavior,
        margin: margin,
        action: action,
      ),
    );
  }
}
