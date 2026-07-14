import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class Notify {
  static void success(BuildContext context, String title, [String? description]) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: const Offset(0, 0),
          ).animate(animation),
          child: child,
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      showProgressBar: false,
    );
  }

  static void error(BuildContext context, String title, [String? description]) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      animationBuilder: (context, animation, alignment, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: const Offset(0, 0),
          ).animate(animation),
          child: child,
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      showProgressBar: false,
    );
  }

  static void info(BuildContext context, String title, [String? description]) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 4),
      borderRadius: BorderRadius.circular(12.0),
      showProgressBar: false,
    );
  }
}
