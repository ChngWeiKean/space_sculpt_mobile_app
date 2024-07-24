import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class Toast {
  static void showSuccessToast({
    required String title,
    required String description,
    required BuildContext context,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.minimal,
      icon: const Icon(Icons.check_circle),
      title: Text(title),
      description: Text(description),
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void showErrorToast({
    required String title,
    required String description,
    required BuildContext context,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.minimal,
      icon: const Icon(Icons.error),
      title: Text(title),
      description: Text(description),
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  static void showInfoToast({
    required String title,
    required String description,
    required BuildContext context,
  }) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.minimal,
      icon: const Icon(Icons.info),
      title: Text(title),
      description: Text(description),
      showProgressBar: true,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }
}