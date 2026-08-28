import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_controller.dart';

class _TrackingJiShuQiController extends JiShuQiController {
  int scrollToBottomCalls = 0;

  @override
  void scrollBettingListToBottom() {
    scrollToBottomCalls++;
  }
}

void main() {
  testWidgets('scrolls to the bottom after the keyboard inset settles', (tester) async {
    final controller = _TrackingJiShuQiController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(focusNode: controller.focusNode),
        ),
      ),
    );
    controller.focusNode.requestFocus();
    await tester.pump();
    expect(controller.focusNode.hasFocus, isTrue);

    controller.onKeyboardInsetChanged(40);
    await tester.pump(const Duration(milliseconds: 100));
    controller.onKeyboardInsetChanged(280);

    // An unrelated rebuild with the same inset must not restart the debounce.
    await tester.pump(const Duration(milliseconds: 100));
    controller.onKeyboardInsetChanged(280);
    await tester.pump(const Duration(milliseconds: 159));
    expect(controller.scrollToBottomCalls, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.scrollToBottomCalls, 1);

    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.scrollToBottomCalls, 1);

    // A decreasing inset belongs to keyboard dismissal and must not schedule another scroll.
    controller.onKeyboardInsetChanged(200);
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.scrollToBottomCalls, 1);

    controller.focusNode.unfocus();
    await tester.pump();
    controller.onKeyboardInsetChanged(0);
    await tester.pump(const Duration(milliseconds: 700));
    expect(controller.scrollToBottomCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets('user drag cancels pending scroll-to-bottom retries', (tester) async {
    final controller = JiShuQiController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Listener(
            onPointerDown: (_) => controller.cancelPendingBettingListAutoScroll(),
            child: ListView.builder(
              controller: controller.scrollController,
              itemExtent: 40,
              itemCount: 100,
              itemBuilder: (_, index) => Text('row $index'),
            ),
          ),
        ),
      ),
    );

    controller.scrollBettingListToBottom();
    await tester.pump();
    expect(controller.scrollController.position.extentAfter, 0);

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    final offsetAfterDrag = controller.scrollController.offset;
    expect(offsetAfterDrag, lessThan(controller.scrollController.position.maxScrollExtent));

    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.scrollController.offset, offsetAfterDrag);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });
}
