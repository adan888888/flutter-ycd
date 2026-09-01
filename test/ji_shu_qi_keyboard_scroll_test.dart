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

class _EyeJumpJiShuQiController extends JiShuQiController {
  int jumpToEyeCalls = 0;

  @override
  void jumpToCurrentTempIndexRow() {
    jumpToEyeCalls++;
    final max = scrollController.position.maxScrollExtent;
    scrollController.jumpTo(max - 300);
  }
}

bool _handleBettingListScrollNotification(
  JiShuQiController controller,
  ScrollNotification notification,
) {
  if (notification is ScrollStartNotification &&
      notification.dragDetails != null) {
    controller.onBettingListUserDragStart();
  } else if (notification is ScrollUpdateNotification &&
      notification.dragDetails != null) {
    controller.onBettingListUserDragPositionChanged();
  } else if (notification is ScrollEndNotification) {
    controller.onBettingListUserDragEnd();
  }
  return false;
}

class _KeyboardViewportHarness extends StatefulWidget {
  const _KeyboardViewportHarness({super.key, required this.controller});

  final JiShuQiController controller;

  @override
  State<_KeyboardViewportHarness> createState() =>
      _KeyboardViewportHarnessState();
}

class _KeyboardViewportHarnessState extends State<_KeyboardViewportHarness> {
  double keyboardInset = 0;

  void setKeyboardInset(double value) {
    setState(() => keyboardInset = value);
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.onKeyboardInsetChanged(keyboardInset);
    return SizedBox(
      height: 500,
      child: Column(
        children: [
          Offstage(
            offstage: keyboardInset > 0,
            child: const SizedBox(height: 120),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) =>
                  _handleBettingListScrollNotification(
                widget.controller,
                notification,
              ),
              child: ListView.builder(
                controller: widget.controller.scrollController,
                itemExtent: 40,
                itemCount: 100,
                itemBuilder: (_, index) => Text('row $index'),
              ),
            ),
          ),
          SizedBox(height: 40 + keyboardInset),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('scrolls to the bottom after the keyboard inset settles',
      (tester) async {
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

    // A keyboard-height adjustment can decrease to another non-zero value. It must
    // debounce again and scroll using that stable viewport.
    controller.onKeyboardInsetChanged(200);
    await tester.pump(const Duration(milliseconds: 259));
    expect(controller.scrollToBottomCalls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(controller.scrollToBottomCalls, 2);

    controller.focusNode.unfocus();
    await tester.pump();
    controller.onKeyboardInsetChanged(100);
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.scrollToBottomCalls, 2);
    controller.onKeyboardInsetChanged(0);
    await tester.pump();
    expect(controller.scrollToBottomCalls, 3);
    await tester.pump(const Duration(milliseconds: 700));
    expect(controller.scrollToBottomCalls, 3);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets(
      'keeps the list at bottom while the keyboard viewport is restored',
      (tester) async {
    final controller = JiShuQiController();
    final harnessKey = GlobalKey<_KeyboardViewportHarnessState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _KeyboardViewportHarness(
            key: harnessKey,
            controller: controller,
          ),
        ),
      ),
    );

    harnessKey.currentState!.setKeyboardInset(280);
    await tester.pump();
    controller.scrollBettingListToBottom();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.scrollController.position.extentAfter,
        lessThanOrEqualTo(1.5));

    // An overscroll gesture that remains at the bottom must keep the pin intent.
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.scrollController.position.extentAfter,
        lessThanOrEqualTo(1.5));

    // With no eye target the FAB is a no-op, so closing the keyboard must still
    // restore the list to the bottom.
    controller.state.isBettingListAtBottom = true;
    expect(controller.state.currentTempIndex, 0);
    controller.onBettingListJumpFabTap();

    harnessKey.currentState!.setKeyboardInset(40);
    await tester.pump();
    harnessKey.currentState!.setKeyboardInset(0);
    await tester.pump();

    // The chart returning at inset zero makes the viewport 80 px shorter. The
    // close handler deliberately waits for this layout before correcting it.
    expect(controller.scrollController.position.extentAfter, greaterThan(50));
    await tester.pump();
    expect(controller.scrollController.position.extentAfter,
        lessThanOrEqualTo(1.5));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets(
      'does not force the restored viewport to bottom after a real user drag',
      (tester) async {
    final controller = JiShuQiController();
    final harnessKey = GlobalKey<_KeyboardViewportHarnessState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _KeyboardViewportHarness(
            key: harnessKey,
            controller: controller,
          ),
        ),
      ),
    );

    harnessKey.currentState!.setKeyboardInset(280);
    await tester.pump();
    controller.scrollBettingListToBottom();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    final offsetAfterDrag = controller.scrollController.offset;
    expect(controller.scrollController.position.extentAfter, greaterThan(100));

    harnessKey.currentState!.setKeyboardInset(40);
    await tester.pump();
    harnessKey.currentState!.setKeyboardInset(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.scrollController.offset, offsetAfterDrag);
    expect(controller.scrollController.position.extentAfter, greaterThan(1.5));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets('jumping to the eye row cancels old bottom-scroll retries',
      (tester) async {
    final controller = _EyeJumpJiShuQiController();
    final harnessKey = GlobalKey<_KeyboardViewportHarnessState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _KeyboardViewportHarness(
            key: harnessKey,
            controller: controller,
          ),
        ),
      ),
    );

    harnessKey.currentState!.setKeyboardInset(280);
    await tester.pump();
    controller.scrollBettingListToBottom();
    await tester.pump();
    expect(controller.scrollController.position.extentAfter,
        lessThanOrEqualTo(1.5));

    controller.state.isBettingListAtBottom = true;
    controller.state.currentTempIndex = 1;
    controller.onBettingListJumpFabTap();
    expect(controller.jumpToEyeCalls, 1);

    final offsetAfterEyeJump = controller.scrollController.offset;
    expect(controller.scrollController.position.extentAfter, greaterThan(250));
    harnessKey.currentState!.setKeyboardInset(40);
    await tester.pump();
    harnessKey.currentState!.setKeyboardInset(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.scrollController.offset, offsetAfterEyeJump);
    expect(controller.scrollController.position.extentAfter, greaterThan(1.5));

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets('a drag start cancels an already scheduled close correction',
      (tester) async {
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
    controller.onKeyboardInsetChanged(280);
    await tester.pump(const Duration(milliseconds: 260));
    expect(controller.scrollToBottomCalls, 1);

    controller.focusNode.unfocus();
    controller.onKeyboardInsetChanged(0);
    controller.onBettingListUserDragStart();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.scrollToBottomCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets('user drag cancels pending scroll-to-bottom retries',
      (tester) async {
    final controller = JiShuQiController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _handleBettingListScrollNotification(
              controller,
              notification,
            ),
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
    expect(offsetAfterDrag,
        lessThan(controller.scrollController.position.maxScrollExtent));

    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.scrollController.offset, offsetAfterDrag);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });
}
