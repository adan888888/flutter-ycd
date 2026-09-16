import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_view.dart';

void main() {
  test('bet input uses 31pt only while the keyboard is open', () {
    expect(jiShuQiBetInputFontSize(300), 31);
    expect(jiShuQiBetInputFontSize(1), 31);
    expect(jiShuQiBetInputFontSize(0), isNull);
    expect(jiShuQiBetInputCursorHeight(300), 31);
    expect(jiShuQiBetInputCursorHeight(0), isNull);
    expect(
      JiShuQiKeyboardAwareFabLocation.inputBarHeightForKeyboardInset(300),
      JiShuQiKeyboardAwareFabLocation.expandedInputBarHeight,
    );
    expect(
      JiShuQiKeyboardAwareFabLocation.inputBarHeightForKeyboardInset(0),
      JiShuQiKeyboardAwareFabLocation.inputBarHeight,
    );
  });

  testWidgets('right fifth of the input bar does not accept touches',
      (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500,
              height: JiShuQiKeyboardAwareFabLocation.inputBarHeight,
              child: JiShuQiInputTouchGuard(
                child: TextField(focusNode: focusNode),
              ),
            ),
          ),
        ),
      ),
    );

    final guardRect = tester.getRect(find.byType(JiShuQiInputTouchGuard));
    await tester.tapAt(
        Offset(guardRect.left + guardRect.width * 0.5, guardRect.center.dy));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();
    await tester.tapAt(
        Offset(guardRect.left + guardRect.width * 0.9, guardRect.center.dy));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    focusNode.dispose();
  });

  testWidgets('action buttons do not trigger input tap outside',
      (tester) async {
    final focusNode = FocusNode();
    var outsideTapCount = 0;
    var buttonTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                focusNode: focusNode,
                onTapOutside: (_) => outsideTapCount++,
              ),
              TextFieldTapRegion(
                child: TextButton(
                  onPressed: () => buttonTapCount++,
                  child: const Text('P+'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('P+'));
    await tester.pump();

    expect(buttonTapCount, 1);
    expect(outsideTapCount, 0);
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    focusNode.dispose();
  });

  testWidgets('random FAB does not trigger input tap outside', (tester) async {
    final focusNode = FocusNode();
    var outsideTapCount = 0;
    var fabTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            focusNode: focusNode,
            onTapOutside: (_) => outsideTapCount++,
          ),
          floatingActionButton: TextFieldTapRegion(
            child: FloatingActionButton(
              onPressed: () => fabTapCount++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(fabTapCount, 1);
    expect(outsideTapCount, 0);
    expect(focusNode.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    focusNode.dispose();
  });

  testWidgets('large iOS bet input supports a floating cursor drag',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = TextEditingController(text: '2256');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: 320,
              height: JiShuQiKeyboardAwareFabLocation.expandedInputBarHeight,
              child: TextField(
                controller: controller,
                cursorHeight: jiShuQiBetInputCursorHeight(300),
                style: TextStyle(fontSize: jiShuQiBetInputFontSize(300)),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.only(bottom: 7),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final inputCenter = tester.getCenter(find.byType(TextField));
    final gesture = await tester.startGesture(inputCenter);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final gestureException = tester.takeException();
    debugDefaultTargetPlatformOverride = null;
    expect(gestureException, isNull);
  });

  testWidgets('random FAB moves above the input bar while the keyboard is open',
      (tester) async {
    const fabKey = ValueKey('test_random_fab');
    const viewPaddingBottom = 24.0;
    var tapCount = 0;

    Future<void> pumpWithKeyboardInset(double keyboardInset) {
      final remainingPadding = viewPaddingBottom > keyboardInset
          ? viewPaddingBottom - keyboardInset
          : 0.0;
      return tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(
                bottom: remainingPadding,
              ),
              viewPadding: const EdgeInsets.only(bottom: viewPaddingBottom),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
            ),
            child: child!,
          ),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            floatingActionButtonLocation: JiShuQiKeyboardAwareFabLocation(
              keyboardInset: keyboardInset,
              viewPaddingBottom: viewPaddingBottom,
            ),
            floatingActionButtonAnimator:
                FloatingActionButtonAnimator.noAnimation,
            floatingActionButton: Transform.scale(
              scale: JiShuQiKeyboardAwareFabLocation.randomFabScale,
              child: FloatingActionButton(
                key: fabKey,
                onPressed: () => tapCount++,
              ),
            ),
          ),
        ),
      );
    }

    await pumpWithKeyboardInset(0);
    final closedCenter = tester.getCenter(find.byKey(fabKey));

    // During the first IME frames the remaining safe padding still occupies the
    // bottom. The FAB must already sit above the input bar and remain tappable.
    const earlyKeyboardInset = 10.0;
    await pumpWithKeyboardInset(earlyKeyboardInset);
    var openRect = tester.getRect(find.byKey(fabKey));
    var scaffoldBottom = tester.getBottomRight(find.byType(Scaffold)).dy;
    var inputBarCenter = scaffoldBottom -
        viewPaddingBottom -
        JiShuQiKeyboardAwareFabLocation.expandedInputBarHeight / 2;
    expect(openRect.center.dy, closeTo(inputBarCenter, 0.01));
    await tester.tapAt(openRect.center);
    expect(tapCount, 1);

    const keyboardInset = 300.0;
    await pumpWithKeyboardInset(keyboardInset);
    openRect = tester.getRect(find.byKey(fabKey));
    expect(openRect.center.dy, lessThan(closedCenter.dy));
    scaffoldBottom = tester.getBottomRight(find.byType(Scaffold)).dy;
    inputBarCenter = scaffoldBottom -
        keyboardInset -
        JiShuQiKeyboardAwareFabLocation.expandedInputBarHeight / 2;
    expect(openRect.center.dy, closeTo(inputBarCenter, 0.01));
    await tester.tapAt(openRect.center);
    expect(tapCount, 2);

    await pumpWithKeyboardInset(0);
    expect(tester.getCenter(find.byKey(fabKey)), closedCenter);
  });
}
