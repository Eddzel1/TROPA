import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tropa_v2/widgets/keyboard_safe_body.dart';

/// A page shaped like Dues/Members/Households: fixed parts above an `Expanded` list.
Widget page(double height) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: height,
            child: KeyboardSafeBody(
              minHeight: 500,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 300, child: Text('header and filters')),
                  const TextField(),
                  Expanded(child: ListView(children: [for (var i = 0; i < 30; i++) Text('row $i')])),
                ],
              ),
            ),
          ),
        ),
      ),
    );


/// Whether the helper's scroll view can scroll (it is always there, so the tree never changes shape).
bool scrolls(WidgetTester tester) =>
    tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView)).physics is! NeverScrollableScrollPhysics;

void main() {
  testWidgets('scrolls instead of overflowing when the keyboard leaves little room', (tester) async {
    await tester.pumpWidget(page(380));
    expect(tester.takeException(), isNull);
    expect(scrolls(tester), isTrue);
    expect(find.text('row 0'), findsOneWidget);
  });

  testWidgets('keeps the normal layout when there is room', (tester) async {
    await tester.pumpWidget(page(700));
    expect(tester.takeException(), isNull);
    expect(scrolls(tester), isFalse);
  });

  testWidgets('without the helper the same page overflows (the reported bug)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 380,
            child: Column(
              children: [
                const SizedBox(height: 360, child: Text('header and filters')),
                const TextField(),
                Expanded(child: ListView(children: const [Text('row 0')])),
              ],
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNotNull);
  });

  for (final screenHeight in [900.0, 420.0]) {
    testWidgets('inside an AlertDialog like the Officer dialog ($screenHeight px screen)', (tester) async {
      tester.view.physicalSize = Size(500, screenHeight);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AlertDialog(
            title: const Text('Assign officer'),
            content: SizedBox(
              width: 400,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 460),
                child: KeyboardSafeBody(
                  minHeight: 460,
                  child: Column(
                    children: [
                      const TextField(),
                      const SizedBox(height: 200),
                      Expanded(child: ListView(children: [for (var i = 0; i < 30; i++) Text('member $i')])),
                    ],
                  ),
                ),
              ),
            ),
            actions: [TextButton(onPressed: () {}, child: const Text('Save'))],
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(scrolls(tester), screenHeight < 600);
    });
  }

  testWidgets('a focused field keeps focus while the keyboard shrinks the room (keyboard stays up)', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    Widget at(double height) => MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: height,
                child: KeyboardSafeBody(
                  minHeight: 500,
                  child: Column(
                    children: [
                      const SizedBox(height: 300),
                      TextField(focusNode: focus),
                      Expanded(child: ListView(children: const [Text('row 0')])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(at(700));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    final field = tester.state(find.byType(EditableText));

    // The keyboard opening takes the height below minHeight, then it closes again.
    for (final h in [600.0, 450.0, 380.0, 700.0]) {
      await tester.pumpWidget(at(h));
      expect(focus.hasFocus, isTrue, reason: 'lost focus at $h px');
      expect(tester.state(find.byType(EditableText)), same(field), reason: 'field rebuilt at $h px');
    }
  });
}
