import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_view.dart';

void main() {
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
    var inputBarTop = scaffoldBottom -
        viewPaddingBottom -
        JiShuQiKeyboardAwareFabLocation.inputBarHeight;
    expect(openRect.bottom, closeTo(inputBarTop, 0.01));
    await tester.tapAt(openRect.center);
    expect(tapCount, 1);

    const keyboardInset = 300.0;
    await pumpWithKeyboardInset(keyboardInset);
    openRect = tester.getRect(find.byKey(fabKey));
    expect(openRect.center.dy, lessThan(closedCenter.dy));
    scaffoldBottom = tester.getBottomRight(find.byType(Scaffold)).dy;
    inputBarTop = scaffoldBottom -
        keyboardInset -
        JiShuQiKeyboardAwareFabLocation.inputBarHeight;
    expect(openRect.bottom, closeTo(inputBarTop, 0.01));
    await tester.tapAt(openRect.center);
    expect(tapCount, 2);

    await pumpWithKeyboardInset(0);
    expect(tester.getCenter(find.byKey(fabKey)), closedCenter);
  });
}
