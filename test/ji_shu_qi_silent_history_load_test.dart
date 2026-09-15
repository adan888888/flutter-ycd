import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/my_db/jsq_bet_record_model.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_controller.dart';

class _SilentHistoryController extends JiShuQiController {
  int loadCalls = 0;
  final Completer<int> pendingLoad = Completer<int>();

  @override
  Future<int> onLoadMore({
    int count = 250,
    bool preserveViewport = true,
  }) {
    loadCalls++;
    return pendingLoad.future;
  }
}

void main() {
  testWidgets('near the top, user scrolling silently loads history once',
      (tester) async {
    final controller = _SilentHistoryController();
    controller.state.betRecordList.add(JsqBetRecordModel(id: 100));

    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller.scrollController,
          itemExtent: 40,
          itemCount: 100,
          itemBuilder: (_, index) => Text('row $index'),
        ),
      ),
    );

    controller.onBettingListUserDragStart();
    controller.onBettingListUserDragPositionChanged();
    controller.onBettingListUserDragPositionChanged();

    expect(controller.loadCalls, 1);
    expect(controller.isLoadingBettingHistory, isTrue);

    controller.pendingLoad.complete(1);
    await tester.pump();
    expect(controller.isLoadingBettingHistory, isFalse);

    // 请求已结束后，同一次拖动尚未结束也不能立即再拉一页。
    controller.onBettingListUserDragPositionChanged();
    expect(controller.loadCalls, 1);

    // 用户重新开始一次拖动后，才允许触发下一页。
    controller.onBettingListUserDragEnd();
    controller.onBettingListUserDragStart();
    controller.onBettingListUserDragPositionChanged();
    expect(controller.loadCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });

  testWidgets('away from the top, user scrolling does not load history',
      (tester) async {
    final controller = _SilentHistoryController();
    controller.state.betRecordList.add(JsqBetRecordModel(id: 100));

    await tester.pumpWidget(
      MaterialApp(
        home: ListView.builder(
          controller: controller.scrollController,
          itemExtent: 40,
          itemCount: 100,
          itemBuilder: (_, index) => Text('row $index'),
        ),
      ),
    );
    controller.scrollController.jumpTo(1000);

    controller.onBettingListUserDragStart();
    controller.onBettingListUserDragPositionChanged();
    controller.onBettingListUserDragEnd();

    expect(controller.loadCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.focusNode.dispose();
    controller.textEditingController.dispose();
    controller.scrollController.dispose();
    controller.roadMapScrollController.dispose();
  });
}
