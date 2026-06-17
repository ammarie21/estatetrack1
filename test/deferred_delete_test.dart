import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/utils/deferred_delete.dart';

void main() {
  testWidgets('undo closes snackbar and restores item', (tester) async {
    var items = <String>['return-1'];
    var committed = false;
    late BuildContext screenContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            screenContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final deleteFuture = deferredDelete(
      context: screenContext,
      message: 'Return record removed',
      onRemove: () => items = [],
      onRestore: () => items = ['return-1'],
      commit: () async {
        committed = true;
      },
      undoWindow: const Duration(milliseconds: 200),
    );

    await tester.pump();
    expect(items, isEmpty);
    expect(find.text('Undo'), findsOneWidget);

    final undoAction = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    undoAction.onPressed();
    await tester.pumpAndSettle();
    await deleteFuture;

    expect(items, ['return-1']);
    expect(find.text('Undo'), findsNothing);
    expect(committed, isFalse);
  });

  testWidgets('snackbar clears after undo window and commits', (tester) async {
    var committed = false;
    late BuildContext screenContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            screenContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final deleteFuture = deferredDelete(
      context: screenContext,
      message: 'Return record removed',
      onRemove: () {},
      onRestore: () {},
      commit: () async {
        committed = true;
      },
      undoWindow: const Duration(milliseconds: 200),
    );

    await tester.pump();
    expect(find.text('Undo'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 250));
    await deleteFuture;
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
    expect(committed, isTrue);
  });
}
