// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/my_widget/baccarat_big_road_widget.dart';
import 'package:ycd/utils/day_night_theme.dart';
import 'package:ycd/utils/network/get_store.dart';

import '../../my_widget/daily_goal_progress_bar.dart';
import '../../my_widget/vertical_text.dart';
import 'ji_shu_qi_controller.dart';
import 'ji_shu_qi_state.dart';

double? jiShuQiBetInputFontSize(double keyboardInset) => keyboardInset > 0 ? 46 : null;
double? jiShuQiBetInputCursorHeight(double keyboardInset) => jiShuQiBetInputFontSize(keyboardInset);

/// 首次页面数据仍在 loading 时不抢先展示空态；加载结束后才显示“暂无记录”。
class JiShuQiBettingListEmptyState extends StatelessWidget {
  const JiShuQiBettingListEmptyState({
    super.key,
    required this.isInitialDataLoading,
  });

  final bool isInitialDataLoading;

  @override
  Widget build(BuildContext context) {
    if (isInitialDataLoading) return const SizedBox.shrink();
    return Center(
      child: Image.asset(
        JiShuQiState.emptyBettingListAsset,
        width: 80,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// 键盘弹起时把骰子按钮布局到输入栏上方；键盘收起时沿用 Scaffold 原本的位置。
class JiShuQiKeyboardAwareFabLocation extends FloatingActionButtonLocation {
  const JiShuQiKeyboardAwareFabLocation({
    required this.keyboardInset,
    required this.viewPaddingBottom,
  });

  static const double inputBarHeight = 40;
  static const double expandedInputBarHeight = 64;
  static const double randomFabScale = 0.8;

  static double inputBarHeightForKeyboardInset(double keyboardInset) =>
      keyboardInset > 0 ? expandedInputBarHeight : inputBarHeight;

  final double keyboardInset;
  final double viewPaddingBottom;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base = FloatingActionButtonLocation.endDocked.getOffset(scaffoldGeometry);
    if (keyboardInset <= 0) return base;

    final fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final fabVisualRadius = fabHeight * randomFabScale / 2;
    final bottomObstruction = keyboardInset > viewPaddingBottom ? keyboardInset : viewPaddingBottom;
    final effectiveInputBarHeight = inputBarHeightForKeyboardInset(keyboardInset);
    final inputBarTop = scaffoldGeometry.scaffoldSize.height - bottomObstruction - effectiveInputBarHeight;
    final targetY = inputBarTop - fabHeight / 2 - fabVisualRadius;
    return Offset(base.dx, targetY < base.dy ? targetY : base.dy);
  }

  @override
  bool operator ==(Object other) =>
      other is JiShuQiKeyboardAwareFabLocation &&
      keyboardInset == other.keyboardInset &&
      viewPaddingBottom == other.viewPaddingBottom;

  @override
  int get hashCode => Object.hash(keyboardInset, viewPaddingBottom);
}

/// 吸收输入栏最右侧五分之一的触摸，避免点击骰子时误聚焦输入框。
class JiShuQiInputTouchGuard extends StatelessWidget {
  const JiShuQiInputTouchGuard({super.key, required this.child});

  static const double disabledFraction = 2 / 7;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: disabledFraction,
            heightFactor: 1,
            child: AbsorbPointer(child: SizedBox.expand()),
          ),
        ),
      ],
    );
  }
}

class JiShuQiView extends GetView<JiShuQiController> {
  const JiShuQiView({super.key});

  /// 「今日目标」、Y 轴刻度与屏幕左缘的统一留白
  static const double _contentLeftInset = 5;

  /// 轴标列与绘图区 / 进度条间距（与 SideTitleWidget space 一致）
  static const double _chartLeftAxisLabelGap = 2;

  /// 轴标列宽（与 fl_chart leftTitles.reservedSize 一致，按最宽刻度估算）
  double _yAxisLabelColumnWidth(TextStyle axisStyle) {
    const probe = '888.8k';
    final painter = TextPainter(
      text: TextSpan(text: probe, style: axisStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  double _yAxisTitlesReservedWidth(TextStyle axisStyle) =>
      _yAxisLabelColumnWidth(axisStyle) + _chartLeftAxisLabelGap;

  double _plotAreaLeftFromScreen(TextStyle axisStyle) =>
      _contentLeftInset + _yAxisTitlesReservedWidth(axisStyle);

  static const double _actionButtonsHeight = 35;

  static const double _topToolBarHeight = 24;

  /// 今日目标/进度条区域与右侧主题/锁/编辑图标间距
  static const double _topBarTrailingIconsGap = 8;

  static const double _chartBelowToolbarGap = 5;

  static const double _lineChartPlotHeight = 120;

  /// 大路顶栏「长龙 / 图例」行（fontSize 13）约高
  static const double _bigRoadLegendRowHeight = 19;

  static const double _bigRoadBottomInset = 2;

  static const int _bigRoadVisibleRows = 6;

  /// 顶栏以下、统计区以上的图表块高度（含与统计区间距 5）
  double _chartBlockBelowToolbarHeight({required bool isBigRoad}) {
    if (isBigRoad) {
      return _bigRoadLegendRowHeight +
          JiShuQiState.cellWidth * _bigRoadVisibleRows +
          _bigRoadBottomInset +
          _chartBelowToolbarGap;
    }
    return _lineChartPlotHeight + _chartBelowToolbarGap;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final inputBarHeight = JiShuQiKeyboardAwareFabLocation.inputBarHeightForKeyboardInset(keyboardInset);
    return Listener(
      onPointerDown: (PointerDownEvent event) => controller.onUserInteraction(),
      onPointerMove: (event) => controller.onUserInteraction(),
      child: GetBuilder<JiShuQiController>(
        builder: (controller) {
          final overlay = DayNightTheme.systemUiOverlayStyle(controller.state.isDarkMode);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: Scaffold(
          backgroundColor: controller.state.currentBgColor,
          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation: JiShuQiKeyboardAwareFabLocation(
            keyboardInset: keyboardInset,
            viewPaddingBottom: viewPaddingBottom,
          ),
          floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
          floatingActionButton: Transform.scale(
            scale: JiShuQiKeyboardAwareFabLocation.randomFabScale,
            child: GetBuilder<JiShuQiController>(
              builder: (controller) {
                return AnimatedScale(
                  scale: controller.state.floatButtonScale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Semantics(
                    button: true,
                    label: '随机庄闲',
                    hint: '长按打开更多功能',
                    child: GestureDetector(
                      onLongPress: () {
                        controller.guardAgainstKeyboardPop();
                        controller.showBottomFunction();
                      },
                      child: FloatingActionButton(
                        key: const ValueKey('ji_shu_qi_random_fab'),
                        backgroundColor: Colors.transparent,
                        onPressed: () {
                          controller.guardAgainstKeyboardPop();
                          // 触发点击动画：放大1.5倍再缩小
                          controller.state.floatButtonScale = 2;
                          controller.update();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            controller.state.floatButtonScale = 1.0;
                            controller.update();
                          });
                          // 执行随机逻辑
                          controller.setRandom((int _) => debugPrint(_.toString()));
                        },
                        child: Image.asset('assets/images/shai.png'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          body: SafeArea(
            child: GetBuilder<JiShuQiController>(
              builder: (controller) => LayoutBuilder(
                builder: (context, constraints) {
                  // 获取图表区域的高度（如果显示）
                  double? chartHeight;
                  if (controller.state.isChartVisible) {
                    // 折线图固定高度120，大路图需要动态计算
                    chartHeight = controller.state.isBigRoad ? null : 120.0;
                  }
                  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                  controller.onKeyboardInsetChanged(keyboardInset);
                  // 键盘弹出时用 Offstage 藏图表（保留挂载，避免卸载导致输入框失焦）
                  final keyboardOpen = keyboardInset > 0;
                  final showChart = controller.state.isChartVisible;

                  /// 顶栏 + 图表 + 统计 + 按钮区一体下拉刷新（逻辑仍为 refreshStatsArea）
                  Widget buildHeaderRefreshSection() {
                    final chartPartHeight = _chartRefreshSectionHeight(
                      showChart: showChart,
                      keyboardOpen: keyboardOpen,
                      isBigRoad: controller.state.isBigRoad,
                    );
                    const statsHeight = JiShuQiState.statsAreaHeight;
                    final totalHeight =
                        chartPartHeight + statsHeight + _actionButtonsHeight;

                    return SizedBox(
                      height: totalHeight,
                      child: GetBuilder<JiShuQiController>(
                        builder: (c) => EasyRefresh(
                          controller: c.statsRefreshController,
                          header: c.state.pullRefreshHeader(backgroundColor: c.state.currentBgColor),
                          onRefresh: c.refreshStatsArea,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: totalHeight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTopToolBar(c, showChart: showChart),
                                    if (!keyboardOpen && showChart) ...[
                                      _buildLineChats(),
                                      const SizedBox(height: _chartBelowToolbarGap),
                                    ],
                                    SizedBox(
                                      height: statsHeight,
                                      child: _buildStatsTable(c),
                                    ),
                                    _buildActionButtonsRow(c),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTap: controller.dismissKeyboard,
                            child: buildHeaderRefreshSection(),
                          ),
                          //列表
                          Expanded(
                            child: GetBuilder<JiShuQiController>(
                                builder: (controller) => AbsorbPointer(
                                      absorbing: controller.state.isRefreshing,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: controller.dismissKeyboard,
                                        child: ColoredBox(
                                          color: controller.state.currentListViewColor,
                                          child: EasyRefresh(
                                            controller: controller.refreshcontroller,
                                            header: controller.state.pullRefreshHeader(
                                              backgroundColor: controller.state.currentListViewColor,
                                            ),
                                            footer: const ClassicFooter(
                                              clamping: true,
                                              infiniteOffset: null,
                                              triggerWhenReach: false,
                                              triggerWhenRelease: true,
                                              dragText: '上拉加载',
                                              armedText: '松开加载',
                                              readyText: '加载中...',
                                              processingText: '加载中...',
                                              processedText: '加载成功',
                                              noMoreText: '没有更多了',
                                              failedText: '加载失败',
                                              messageText: '更新时间 %T',
                                              showMessage: true,
                                            ),
                                            onRefresh: () async => controller.onLoadMore(),
                                            child: controller.state.betRecordList.isEmpty
                                                ? JiShuQiBettingListEmptyState(
                                                    isInitialDataLoading: controller.state.isInitialDataLoading,
                                                  )
                                                : NotificationListener<ScrollNotification>(
                                                    onNotification: (notification) {
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
                                                    },
                                                    child: ListView.builder(
                                                      key: const PageStorageKey<String>(
                                                        'ji_shu_qi_betting_list',
                                                      ),
                                                      reverse: false,
                                                      controller: controller.scrollController,
                                                      itemCount: controller.state.betRecordList.length,
                                                      itemBuilder: (BuildContext context, int index) =>
                                                          _buildItem(index),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    )),
                          ),
                          // 输入栏：仅此处随键盘上移，统计区不参与整体上移
                          Padding(
                            padding: EdgeInsets.only(bottom: keyboardInset),
                            child: SafeArea(
                              top: false,
                              bottom: keyboardInset == 0,
                              child: SizedBox(
                                height: inputBarHeight,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: ListenableBuilder(
                                        listenable: controller.focusNode,
                                        builder: (context, _) {
                                          final borderColor = controller.focusNode.hasFocus
                                              ? controller.state.currentRestartRowBorderColor
                                              : (controller.state.isDarkMode ? Colors.white24 : Colors.grey);
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(width: 1, color: borderColor),
                                              ),
                                            ),
                                            child: JiShuQiInputTouchGuard(
                                              child: Row(
                                                children: [
                                                  GestureDetector(
                                                    // 排序
                                                    onTap: () => controller.sort(),
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Icon(
                                                        CupertinoIcons.arrow_up_arrow_down,
                                                        color: controller.state.currentTextColor,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Theme(
                                                      data: Theme.of(context).copyWith(
                                                        textSelectionTheme: TextSelectionThemeData(
                                                          selectionColor: controller.state.isDarkMode
                                                              ? Colors.white.withValues(alpha: 0.4)
                                                              : Colors.blue.withValues(alpha: 0.3),
                                                          selectionHandleColor:
                                                              controller.state.isDarkMode ? Colors.white : Colors.blue,
                                                        ),
                                                      ),
                                                      child: TextField(
                                                        key: const ValueKey('ji_shu_qi_bet_input'),
                                                        focusNode: controller.focusNode,
                                                        autofocus: false,
                                                        controller: controller.textEditingController,
                                                        onTapOutside: (_) => controller.onInputTapOutside(),
                                                        onChanged: (value) {},
                                                        keyboardType:
                                                            const TextInputType.numberWithOptions(decimal: true),
                                                        textInputAction: TextInputAction.done,
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                                        ],
                                                        cursorColor:
                                                            controller.state.isDarkMode ? Colors.white : Colors.blue,
                                                        cursorHeight: jiShuQiBetInputCursorHeight(keyboardInset),
                                                        style: TextStyle(
                                                          fontSize: jiShuQiBetInputFontSize(keyboardInset),
                                                          color: controller.state.currentTextColor,
                                                        ),
                                                        decoration: InputDecoration(
                                                          contentPadding: const EdgeInsets.only(bottom: 7),
                                                          border: InputBorder.none,
                                                          enabledBorder: InputBorder.none,
                                                          focusedBorder: InputBorder.none,
                                                          hintText: "请输入下注金额",
                                                          hintStyle: TextStyle(
                                                            fontSize: 12,
                                                            color: controller.state.isDarkMode
                                                                ? controller.state.darkTextColor.withValues(alpha: 0.54)
                                                                : Colors.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (keyboardInset == 0) SizedBox(height: (!kIsWeb && Platform.isAndroid) ? 5 : 0),
                        ],
                      ),
                      // 悬浮按钮：切换图表显示/隐藏（叠加在图表和统计区之间）
                      if (showChart && !keyboardOpen)
                        Positioned(
                          top: chartHeight != null
                              ? chartHeight - 20 // 折线图：图表高度120，按钮高度40，居中在图表底部
                              : 80 - 20, // 大路图：估算高度80（标题行约30px + 大路图约50px），按钮居中在图表底部
                          right: 0,
                          child: GestureDetector(
                            onTap: () => controller.toggleChartVisibility(),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: controller.state.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: controller.state.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.black.withValues(alpha: 0.4),
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => controller.toggleChartVisibility(),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: controller.state.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: controller.state.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.1),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      // 右下角悬浮钮：在底部↑去眼睛，不在底部↓回最底
                      Positioned(
                        right: -0,
                        bottom: JiShuQiState.jumpToEyeFabBottom + keyboardInset,
                        child: GestureDetector(
                          onTap: controller.onBettingListJumpFabTap,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: controller.state.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              controller.state.isBettingListAtBottom
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: controller.state.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.6),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
          );
        },
      ),
    );
  }

  _buildItem(int index) => GetBuilder<JiShuQiController>(
        builder: (controller) {
          // 由于ListView是reverse的，需要转换index来获取正确的交替颜色
          final actualIndex = controller.state.betRecordList.length - 1 - index;
          // 根据index的奇偶性设置不同的背景色
          final backgroundColor = actualIndex % 2 == 0
              ? (controller.state.isDarkMode
                  ? const Color(0xFF182533) // 微蓝调斑马纹（略浅）
                  : Colors.grey.shade50) // 浅灰白色
              : (controller.state.isDarkMode ? controller.state.darkListViewColor : Colors.grey.shade200); // 稍深一点的浅灰色
          // 重启标记线：该行有重启统计快照则显示底部分隔线
          final restartSnapshot = controller.state.betRecordList[index].restartStatSnapshot?.trim() ?? '';
          final isRestartRow = restartSnapshot.isNotEmpty;
          final rowId = controller.state.betRecordList[index].id;
          final isEyeRow = rowId != null && rowId != 0 && rowId == controller.state.currentTempIndex;
          final shuyingRaw = controller.state.betRecordList[index].shuyingzhi;
          final shuyingDisplay = controller.state.formatShuyingzhiColumn(shuyingRaw);

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 6),
            key: isEyeRow ? controller.tempIndexRowKey : (rowId != null ? ValueKey<int>(rowId) : ValueKey<int>(index)),
            height: JiShuQiState.bettingTableRowHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: isRestartRow ? controller.state.currentRestartRowBorderColor : Colors.transparent,
                  width: isRestartRow ? 0.5 : 0,
                ),
              ),
            ),
            child: Row(
              children: [
                // 序号列：显示序号时含眼睛与局部平衡点击；隐藏时仅占位
                if (controller.state.isSeqVisible)
                  GestureDetector(
                    onTap: () => controller.juBuPingHeng(controller.state.betRecordList[index].id!),
                    child: controller.state.betRecordList[index].id != null &&
                            controller.state.betRecordList[index].id == controller.state.currentTempIndex
                        ? SizedBox(
                            width: JiShuQiState.seqColMaxWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 13,
                                  color: controller.state.isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${controller.state.betRecordList[index].seq}",
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.0,
                                      fontWeight: FontWeight.w200,
                                      color: controller.state.isDarkMode
                                          ? controller.state.darkTextColor.withValues(alpha: 0.7)
                                          : Colors.black45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: JiShuQiState.seqColMaxWidth,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                "${controller.state.betRecordList[index].seq}",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w200,
                                  color: controller.state.isDarkMode
                                      ? controller.state.darkTextColor.withValues(alpha: 0.7)
                                      : Colors.black45,
                                ),
                              ),
                            ),
                          ),
                  )
                else
                  const SizedBox(width: 10),

                // 输赢列：隐藏序号时眼睛与局部平衡点击在此列
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: controller.state.isSeqVisible
                        ? null
                        : () => controller.juBuPingHeng(controller.state.betRecordList[index].id!),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: !controller.state.isSeqVisible &&
                              controller.state.betRecordList[index].id != null &&
                              controller.state.betRecordList[index].id == controller.state.currentTempIndex
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 13,
                                  color: controller.state.isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800,
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: _buildShuyingzhiText(
                                    controller: controller,
                                    display: shuyingDisplay,
                                    raw: shuyingRaw,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: _buildShuyingzhiText(
                                controller: controller,
                                display: shuyingDisplay,
                                raw: shuyingRaw,
                                fontSize: 12.5,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                // 消数列：与输赢列均分剩余宽度；数字区过长缩小字体，右侧保留删除图标
                Expanded(
                  flex: 1,
                  child: Builder(
                    builder: (context) {
                      final xiaoshu = controller.state.betRecordList[index].shuyingzhiXiaoshu;
                      final xiaoshuText = controller.state.formatShuyingzhiColumn(xiaoshu);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  xiaoshuText,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w200,
                                    color: xiaoshuText.isEmpty
                                        ? controller.state.currentTextColor.withValues(alpha: 0.0)
                                        : controller.state.getValueColor(xiaoshu),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: xiaoshu != null,
                            child: GestureDetector(
                              onTap: () => controller.updateLists(index),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: controller.state.currentTextColor.withValues(alpha: 0.75),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                //下注值列：宽约 5 个数字；过长时整体缩小字体（与统计区 FittedBox 一致）
                SizedBox(
                  width: JiShuQiState.betColWidth,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${controller.state.betRecordList[index].xiazhujine}",
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: controller.state.currentTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
                //胜负路
                _sflContainer(index),
                // 重启快照列（最后一列，与输赢/消数列均分剩余宽度）
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: restartSnapshot.isEmpty
                        ? const SizedBox.shrink()
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              restartSnapshot,
                              maxLines: 1,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w100,
                                color: controller.state.isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      );

  _sflContainer(int index) => GetBuilder<JiShuQiController>(
        builder: (controller) {
          final isZhengDa = controller.state.betRecordList[index].shengfulu == '正打';
          final isLose = controller.state.betRecordList[index].remark?.startsWith('-') ?? false;
          final dividerColor = controller.state.isDarkMode ? Colors.white24 : Colors.grey.withValues(alpha: 0.5);

          if (isZhengDa) {
            if (isLose) {
              return Container(
                color: Colors.transparent,
                width: JiShuQiState.sflColWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.negativeColor)),
                    ),
                    _divier(dividerColor, 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.negativeColor)),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                color: Colors.transparent,
                width: JiShuQiState.sflColWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.positiveColor)),
                    ),
                    _divier(dividerColor, 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.positiveColor)),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (isLose) {
              return Container(
                color: Colors.transparent,
                width: JiShuQiState.sflColWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.negativeColor)),
                    ),
                    _divier(dividerColor, 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.positiveColor)),
                    ),
                  ],
                ),
              );
            } else {
              return Container(
                color: Colors.transparent,
                width: JiShuQiState.sflColWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.positiveColor)),
                    ),
                    _divier(dividerColor, 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text("1", style: TextStyle(color: controller.state.negativeColor)),
                    ),
                  ],
                ),
              );
            }
          }
        },
      );

  Widget _buildStatsTable(JiShuQiController controller) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(color: controller.state.currentLineColor, width: 0.1),
        verticalInside: BorderSide(color: controller.state.currentLineColor, width: 1),
      ),
      columnWidths: const {
        1: FlexColumnWidth(1.3),
        0: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        2: FlexColumnWidth(1.3),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: List.generate(
          8,
          (row) => TableRow(
              decoration: BoxDecoration(color: controller.state.currentBgColor),
              children: List.generate(4, (column) {
                final cellWidget = GestureDetector(
                  onTap: () {
                    if (row == 0 && column == 2) {
                      controller.juBuPingHeng(JiShuQiState.tempIndexCmdCancel, v: controller.state.totalValue[29]);
                    }
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3.0, left: 3.0),
                        child: Text(
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              height: 1.35,
                              wordSpacing: 0,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: ((row * 4 + column) == 26 || (row * 4 + column) == 27)
                                  ? Colors.green
                                  : ((row * 4 + column) == 24 || (row * 4 + column) == 22)
                                      ? (controller.state.isDarkMode ? Colors.orange : Colors.red)
                                      : (row * 4 + column) == 2 && controller.state.currentTempIndex != 0
                                          ? Colors.amber
                                          : controller.state.currentTextColor),
                          controller.state.totalValue[row * 4 + column],
                        ),
                      ),
                    ),
                  ),
                );
                return Tooltip(
                  message: controller.state.description[row].elementAt(column),
                  preferBelow: true,
                  verticalOffset: 10,
                  waitDuration: const Duration(seconds: 3),
                  child: cellWidget,
                );
              }).toList())).toList(),
    );
  }

  /// 昵称在折线/图形绘制区内的顶部偏移（Y 轴最高刻度下方）
  static const double _chartNicknameTop = 12;

  TextStyle _chartAxisLikeTextStyle(JiShuQiController controller) => TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: controller.state.isDarkMode ? controller.state.darkTextColor : Colors.black87,
      );

  Color _topBarBackground(JiShuQiController controller, {required bool showChart}) {
    if (!showChart) return controller.state.currentBgColor;
    return controller.state.isBigRoad
        ? controller.state.currentBgColor
        : controller.state.currentChartBgColor;
  }

  double _chartRefreshSectionHeight({
    required bool showChart,
    required bool keyboardOpen,
    required bool isBigRoad,
  }) {
    var h = _topToolBarHeight;
    if (showChart && !keyboardOpen) {
      h += _chartBlockBelowToolbarHeight(isBigRoad: isBigRoad);
    }
    return h;
  }

  Widget _buildActionButtonsRow(JiShuQiController controller) {
    return SizedBox(
      height: _actionButtonsHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _buildButton(controller.state.buttonPositiveBgColor, 'P+', 1),
            _divier2(controller.state.currentTextColor, 38),
            _buildButton(controller.state.buttonPositiveBgColor, 'B+', 2),
            _divier2(controller.state.currentTextColor, 38),
            _buildButton(controller.state.buttonNegativeBgColor, 'P-', 3),
            _divier2(controller.state.currentTextColor, 38),
            _buildButton(controller.state.buttonNegativeBgColor, 'B-', 4),
            _divier2(controller.state.currentTextColor, 38),
            Expanded(
              child: Semantics(
                button: true,
                label: '重启回合',
                hint: '长按打开更多功能',
                child: GestureDetector(
                  key: const ValueKey('restart-round-button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.reStart,
                  onLongPress: controller.showBottomFunction,
                  child: Center(
                    child: Image.asset(
                      'assets/images/restart3.png',
                      height: _actionButtonsHeight,
                      width: _actionButtonsHeight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolBar(JiShuQiController controller, {required bool showChart}) {
    final axisStyle = _chartAxisLikeTextStyle(controller);
    final iconColor = controller.state.isDarkMode ? Colors.white : Colors.black87;
    return ColoredBox(
      color: _topBarBackground(controller, showChart: showChart),
      child: Padding(
        padding: const EdgeInsets.only(left: _contentLeftInset),
        child: SizedBox(
          height: _topToolBarHeight,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                onTap: () {
                  controller.dismissKeyboard();
                  controller.showDailyBetGoalEditor();
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      '今日目标',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: axisStyle,
                    ),
                    const SizedBox(width: _chartLeftAxisLabelGap),
                    Expanded(
                      child: DailyGoalProgressBar(
                        progress: controller.todayBetProgressFraction,
                        isDarkMode: controller.state.isDarkMode,
                        edgeLabel: controller.todayBetProgressPercentLabel,
                        edgeLabelStyle: axisStyle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.todayBetProgressCountLabel,
                      style: axisStyle,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: _topBarTrailingIconsGap),
            GestureDetector(
              onTap: () {
                controller.dismissKeyboard();
                controller.toggleDarkMode();
              },
              child: Icon(
                controller.state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 20,
                color: iconColor,
              ),
            ),
            GestureDetector(
              onTap: () {
                controller.dismissKeyboard();
                controller.lockScreen();
              },
              child: Icon(Icons.lock, size: 20, color: iconColor),
            ),
            GestureDetector(
              onTap: () {
                controller.dismissKeyboard();
                controller.showBottomFunction();
              },
              child: Icon(Icons.edit, size: 20, color: iconColor),
            ),
            const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chartAreaNickname(JiShuQiController controller) {
    final name = GetStore.getInstance().userModel.nickname.trim();
    if (name.isEmpty) return const SizedBox.shrink();
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: controller.state.isDarkMode
            ? controller.state.darkTextColor.withValues(alpha: 0.92)
            : Colors.black87.withValues(alpha: 0.88),
      ),
    );
  }

  _buildLineChats() => GetBuilder<JiShuQiController>(
        builder: (controller) => controller.state.isBigRoad
            ? (controller.state.hasBigRoadData
                //大路子图
                ? GestureDetector(
                    onTap: () => controller.changeChart(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    int.tryParse(controller.state.totalValue[11]) != null &&
                                            int.parse(controller.state.totalValue[11]) > 6
                                        ? ' ${controller.state.totalValue[11]}长龙 '
                                        : '   ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: controller.state.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildLegendItem('W', '赢', Colors.red),
                                      const SizedBox(width: 4),
                                      _buildLegendItem('L', '输', Colors.green),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ],
                              ),
                              // 大路网格
                              BaccaratBigRoadWidget(
                                bigRoadData: controller.state.bigRoad,
                                cellWidth: JiShuQiState.cellWidth,
                                cellHeight: JiShuQiState.cellWidth,
                                hasData: controller.state.hasBigRoadData,
                                scrollController: controller.roadMapScrollController,
                                borderColor: controller.state.isDarkMode ? Colors.white24 : Colors.grey.shade300,
                                backgroundColor:
                                    controller.state.isDarkMode ? const Color(0xFF1E2A3A) : Colors.grey.shade50,
                                borderRadius: 0.0,
                                showBorder: false,
                                front: "W",
                                back: "L",
                                textColor: controller.state.isDarkMode ? controller.state.darkTextColor : Colors.white,
                              ),
                              SizedBox(height: 2)
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: VerticalText(
                            ' 大展鸿图',
                            style: TextStyle(
                              fontSize: 4,
                              color: controller.state.bgColor,
                            ),
                          ),
                        )
                      ],
                    ),
                        Positioned(
                          left: _plotAreaLeftFromScreen(_chartAxisLikeTextStyle(controller)),
                          top: _chartNicknameTop,
                          right: 96,
                          child: IgnorePointer(
                            child: _chartAreaNickname(controller),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text('暂无数据📊'))
            : (controller.state.chartData.isNotEmpty
                ? SizedBox(
                    height: _lineChartPlotHeight,
                    child: Container(
                      color: controller.state.currentChartBgColor,
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        right: 0.0,
                        bottom: 8.0,
                        left: _contentLeftInset,
                      ),
                      child: Builder(
                        builder: (context) {
                          final dataValues = controller.state.chartData.map((e) => e.sales).toList();
                          final dataMinY = dataValues.reduce((a, b) => a < b ? a : b);
                          final dataMaxY = dataValues.reduce((a, b) => a > b ? a : b);
                          final dataSpan = dataMaxY - dataMinY;
                          final fallbackSpan = dataMaxY.abs() * 0.2;
                          final hasUsableSpan = dataSpan.isFinite && dataSpan > 0.000000001;
                          final tickSpan = hasUsableSpan ? dataSpan : (fallbackSpan > 1.0 ? fallbackSpan : 1.0);
                          final tickMinY = hasUsableSpan ? dataMinY : dataMinY - tickSpan / 2;
                          final tickMaxY = hasUsableSpan ? dataMaxY : dataMaxY + tickSpan / 2;
                          final yAxisInterval = tickSpan / 2;
                          final axisPadding = yAxisInterval / 2;
                          final chartMinY = tickMinY - axisPadding;
                          final chartMaxY = tickMaxY + axisPadding;
                          final axisStyle = _chartAxisLikeTextStyle(controller);
                          final yAxisColW = _yAxisLabelColumnWidth(axisStyle);
                          final yAxisReserved = _yAxisTitlesReservedWidth(axisStyle);

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              LineChart(
                            LineChartData(
                              baselineY: tickMinY,
                              backgroundColor: Colors.transparent,
                              borderData: FlBorderData(show: false),
                              //网格线显示和样式
                              gridData: FlGridData(
                                show: true,
                                // x轴线（横线）的间隔
                                horizontalInterval: yAxisInterval,
                                // x轴线（横线）的样式
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    strokeWidth: 1,
                                    dashArray: [5, 5], // 虚线样式（线宽，间隔）
                                  );
                                },
                                //y轴竖线 垂直间隔
                                verticalInterval: 1,
                                // y轴竖线 垂直设置一个很小的值，但不显示垂直网格线
                                getDrawingVerticalLine: (value) {
                                  return const FlLine(
                                    color: Colors.transparent, // 透明色，实际上不显示
                                    strokeWidth: 0,
                                  );
                                },
                              ),
                              //左则轴标数据
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: yAxisReserved,
                                    // 最低值、中间值、最高值固定为三个内部刻度，避免边界标签重叠。
                                    minIncluded: false,
                                    maxIncluded: false,
                                    interval: yAxisInterval,
                                    getTitlesWidget: (value, meta) {
                                      // 列宽贴刻度文字，避免绘图区与轴标之间大块空白
                                      return SideTitleWidget(
                                        meta: meta,
                                        space: _chartLeftAxisLabelGap,
                                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 2),
                                        child: SizedBox(
                                          width: yAxisColW,
                                          child: Text(
                                            _formatValue(value),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.left,
                                            style: axisStyle,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // 添加内边距
                              minX: 0,
                              maxX: controller.state.chartData.length.toDouble() + 0.5,
                              minY: chartMinY,
                              maxY: chartMaxY,
                              // 设置图表边距
                              clipData: const FlClipData.none(),
                              // 添加一些内边距
                              lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: true,
                                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                                  // 单击抬起：切换路子图（内置仍会处理 tooltip / 高亮）
                                  if (event is FlTapUpEvent) {
                                    controller.changeChart();
                                  }
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((touchedSpot) {
                                      return LineTooltipItem(
                                        touchedSpot.y.toStringAsFixed(1),
                                        TextStyle(
                                          color: controller.state.darkTextColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                                  return spotIndexes.map((spotIndex) {
                                    return TouchedSpotIndicatorData(
                                      const FlLine(
                                        color: Colors.transparent, // 透明线条，不显示
                                        strokeWidth: 0,
                                      ),
                                      FlDotData(
                                        show: true, // 显示数据点高亮
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 4,
                                            color: Colors.white,
                                            strokeWidth: 2,
                                            strokeColor: Colors.black,
                                          );
                                        },
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: controller.state.chartData
                                      .map((data) => FlSpot(data.year.toDouble(), data.sales))
                                      .toList(),
                                  // false：点与点用直线连接；true 会用曲线拟合，在急升急跌处容易「鼓包」略过中间点
                                  isCurved: false,
                                  color: controller.state.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  barWidth: 2,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      // 根据相对于上一个点的资金变化设置颜色
                                      Color dotColor;
                                      if (index == 0) {
                                        // 第一个点，无法比较，使用灰色
                                        dotColor = const Color(0xFF6B7280);
                                      } else {
                                        // 获取当前点和上一个点的值
                                        final currentValue = spot.y;
                                        final previousValue = barData.spots[index - 1].y;
                                        final change = currentValue - previousValue;

                                        if (change > 0) {
                                          dotColor = controller.state.positiveColor; // 资金增加
                                        } else if (change < 0) {
                                          dotColor = controller.state.negativeColor; // 资金减少
                                        } else {
                                          dotColor = const Color(0xFF6B7280); // 灰色 - 无变化
                                        }
                                      }
                                      return FlDotCirclePainter(
                                        radius: 2.6,
                                        color: dotColor,
                                        strokeWidth: 0,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                              Positioned(
                                left: _plotAreaLeftFromScreen(axisStyle),
                                top: _chartNicknameTop,
                                right: 36,
                                child: IgnorePointer(
                                  child: _chartAreaNickname(controller),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                : const Text('data')),
      );

  /// 输赢列：整数部分正常字号，小数点及小数部分略小（约 80%）
  Widget _buildShuyingzhiText({
    required JiShuQiController controller,
    required String display,
    required dynamic raw,
    required double fontSize,
  }) {
    final color = controller.state.getValueColor(raw);
    final baseStyle = TextStyle(
      fontSize: fontSize,
      height: 1.0,
      fontWeight: FontWeight.w300,
      color: color,
    );
    final decimalStyle = baseStyle.copyWith(fontSize: fontSize * 0.80);

    var body = display;
    var sign = '';
    if (body.startsWith('+') || body.startsWith('-')) {
      sign = body.substring(0, 1);
      body = body.substring(1);
    }
    final dot = body.indexOf('.');
    if (dot < 0) {
      return Text.rich(
        TextSpan(text: sign + body, style: baseStyle),
        maxLines: 1,
        textAlign: TextAlign.right,
      );
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: sign + body.substring(0, dot), style: baseStyle),
          TextSpan(text: body.substring(dot), style: decimalStyle),
        ],
      ),
      maxLines: 1,
      textAlign: TextAlign.right,
    );
  }

  _divier(Color color, double height) => Container(height: height, width: 1, color: color);

  _divier2(Color color, double height) => Container(height: height, width: 5, color: Colors.transparent);

  _buildButton(Color bg, String str, int i) => Expanded(
        child: SizedBox(
          height: 32,
          child: TextButton(
            style: _buildButtonStyle(bg),
            onLongPress: controller.showBottomFunction,
            onPressed: () {
              switch (i) {
                case 1: //闲赢
                  controller.betRecordButton(1, 'betRecord');
                  break;
                case 2: //庄赢
                  controller.betRecordButton(2, 'betRecord');
                  break;
                case 3: //闲输
                  controller.betRecordButton(3, 'betRecord');
                  break;
                case 4: //庄输
                  controller.betRecordButton(4, 'betRecord');
                  break;
              }
            },
            child: controller.state.isLoading
                ? const CupertinoActivityIndicator()
                : Text(
                    str,
                    style: TextStyle(
                      color: (i == 1 || i == 2)
                          ? controller.state.buttonWinTextColor
                          : controller.state.buttonLossTextColor,
                      fontWeight: FontWeight.bold,
                      height: 0,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      );

  _formatValue(double value) {
    final absValue = value.abs();
    if (absValue >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);
      return '${formatted}k';
    } else if (absValue >= 100) {
      return value.toInt().toString();
    } else if (absValue < 0.1) {
      return '0';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  _buildButtonStyle(Color bg) => ButtonStyle(
        backgroundColor: WidgetStateProperty.all(bg),
        overlayColor: WidgetStateProperty.all(Colors.black),
        padding: WidgetStateProperty.all(EdgeInsetsGeometry.lerp(EdgeInsets.zero, EdgeInsets.zero, 0)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0), // 设置圆角大小
          ),
        ),
      );

  // 构建图例项
  _buildLegendItem(String label1, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(label1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: controller.state.darkTextColor,
                fontSize: 10,
                height: 1.0,
                fontWeight: FontWeight.bold,
              )),
        ),
        const SizedBox(width: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: controller.state.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
