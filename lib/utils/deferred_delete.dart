import 'dart:async';

import 'package:flutter/material.dart';

const Duration kDeferredDeleteWindow = Duration(seconds: 5);

/// Removes an item from the UI immediately, shows an undo snackbar, then
/// commits [commit] to the backend unless the user taps Undo.
Future<void> deferredDelete({
  required BuildContext context,
  required VoidCallback onRemove,
  required VoidCallback onRestore,
  required Future<void> Function() commit,
  required String message,
  Duration undoWindow = kDeferredDeleteWindow,
}) async {
  var undone = false;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  final windowDone = Completer<void>();
  late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;

  void finishWindow() {
    if (!windowDone.isCompleted) {
      windowDone.complete();
    }
  }

  controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: undoWindow,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          undone = true;
          controller.close();
          messenger.hideCurrentSnackBar();
          onRestore();
          finishWindow();
        },
      ),
    ),
  );

  onRemove();

  Timer? undoTimer;
  undoTimer = Timer(undoWindow, () {
    undoTimer = null;
    finishWindow();
  });
  await windowDone.future;
  undoTimer?.cancel();

  if (!undone && context.mounted) {
    messenger.hideCurrentSnackBar();
  }
  if (undone || !context.mounted) return;

  try {
    await commit();
  } catch (_) {
    if (context.mounted) {
      onRestore();
    }
    rethrow;
  }
}
