// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ycd/my_widget/baccarat_big_road_widget.dart';
import 'package:ycd/utils/network/get_store.dart';

import '../../my_widget/vertical_text.dart';
import 'ji_shu_qi_controller.dart';
import 'ji_shu_qi_state.dart';

class JiShuQiView extends GetView<JiShuQiController> {
  const JiShuQiView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) => controller.onUserInteraction(),
      onPointerMove: (event) => controller.onUserInteraction(),
      child: GetBuilder<JiShuQiController>(
        builder: (controller) => Scaffold(
          backgroundColor: controller.state.currentBgColor,
          resizeToAvoidBottomInset: false,
          floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: Transform.scale(
            scale: 0.7,
            child: GetBuilder<JiShuQiController>(
              builder: (controller) {
                return AnimatedScale(
                  scale: controller.state.floatButtonScale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    onPressed: () {
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
                );
              },
            ),
          ),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: GetBuilder<JiShuQiController>(
              builder: (controller) => AppBar(
                  // 隐藏返回键
                  automaticallyImplyLeading: false,
                  actions: [
                    GestureDetector(
                        onTap: () => controller.toggleDarkMode(),
                        child: Icon(
                          controller.state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          size: 20,
                          color: controller.state.isDarkMode ? Colors.white : Colors.black87,
                        )),
                    GestureDetector(
                        onTap: () => controller.lockScreen(),
                        child: Icon(
                          Icons.lock,
                          size: 20,
                          color: controller.state.isDarkMode ? Colors.white : Colors.black87,
                        )),
                    GestureDetector(
                        onTap: () => controller.showBottomFunction(),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: controller.state.isDarkMode ? Colors.white : Colors.black87,
                        )),
                    const SizedBox(
                      width: 10,
                    )
                  ],
                  elevation: 0,
                  toolbarHeight: 20,
                  centerTitle: false,
                  backgroundColor: controller.state.isBigRoad
                      ? controller.state.currentBgColor
                      : controller.state.currentChartBgColor,
                  title: Text(
                    "  $title ${GetStore.getInstance().userModel.nickname}",
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.state.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  )),
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

                  Widget buildStatsArea() {
                    return GetBuilder<JiShuQiController>(
                      builder: (c) => SizedBox(
                        height: JiShuQiState.statsAreaHeight,
                        child: EasyRefresh(
                          controller: c.statsRefreshController,
                          header: c.state.pullRefreshHeader(backgroundColor: c.state.currentBgColor),
                          onRefresh: c.refreshStatsArea,
                          child: ListView(
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [_buildStatsTable(c)],
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
                          Offstage(
                            offstage: keyboardOpen || !showChart,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLineChats(),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTap: controller.dismissKeyboard,
                            child: buildStatsArea(),
                          ),
                          //按钮功能区
                          SizedBox(
                            height: 35,
                            child: Row(
                              children: [
                                SizedBox(width: 2),
                                _divier2(controller.state.currentTextColor, 38),
                                _buildButton(controller.state.buttonPositiveBgColor, "P+", 1),
                                _divier2(controller.state.currentTextColor, 38),
                                _buildButton(controller.state.buttonPositiveBgColor, "B+", 2),
                                _divier2(controller.state.currentTextColor, 38),
                                _buildButton(controller.state.buttonNegativeBgColor, "P-", 3),
                                _divier2(controller.state.currentTextColor, 38),
                                _buildButton(controller.state.buttonNegativeBgColor, "B-", 4),
                                _divier2(controller.state.currentTextColor, 38),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => controller.deleteLast(),
                                  child: Text(
                                    "DEL",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: controller.state.isDarkMode ? Colors.white70 : Colors.black45,
                                    ),
                                  ),
                                ),
                                Container(height: 25, width: 0.5, color: controller.state.currentTextColor),
                                GestureDetector(
                                  onTap: controller.reStart,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 2.0),
                                    child: Image.asset(height: 35, width: 35, 'assets/images/restart3.png'),
                                  ),
                                )
                              ],
                            ),
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
                                            child: ListView.builder(
                                              key: const PageStorageKey<String>('ji_shu_qi_betting_list'),
                                              reverse: false,
                                              controller: controller.scrollController,
                                              itemCount: controller.state.table2List.length,
                                              itemBuilder: (BuildContext context, int index) => _buildItem(index),
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
                                height: 40,
                                child: Row(
                                  children: [
                                    SizedBox(width: 13),
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
                                    SizedBox(width: 5),
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
                                          onChanged: (value) {},
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          textInputAction: TextInputAction.done,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                          ],
                                          cursorColor: controller.state.isDarkMode ? Colors.white : Colors.blue,
                                          style: TextStyle(color: controller.state.currentTextColor),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.only(bottom: 7),
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(
                                                    width: 1, color: controller.state.currentRestartRowBorderColor)),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                width: 1,
                                                color: controller.state.isDarkMode ? Colors.white24 : Colors.grey,
                                              ),
                                            ),
                                            hintText: "请输入下注金额",
                                            hintStyle: TextStyle(
                                              fontSize: 12,
                                              color: controller.state.isDarkMode ? Colors.white54 : Colors.grey,
                                            ),
                                          ),
                                        ),
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
      ),
    );
  }

  _buildItem(int index) => GetBuilder<JiShuQiController>(
        builder: (controller) {
          // 由于ListView是reverse的，需要转换index来获取正确的交替颜色
          final actualIndex = controller.state.table2List.length - 1 - index;
          // 根据index的奇偶性设置不同的背景色
          final backgroundColor = actualIndex % 2 == 0
              ? (controller.state.isDarkMode
                  ? const Color.fromARGB(18, 255, 255, 255) // 微蓝调斑马纹（略浅）
                  : Colors.grey.shade50) // 浅灰白色
              : (controller.state.isDarkMode ? controller.state.darkListViewColor : Colors.grey.shade200); // 稍深一点的浅灰色
          // 重启标记线：该行有重启统计快照则显示底部分隔线
          final restartSnapshot = controller.state.table2List[index].restartStatSnapshot?.trim() ?? '';
          final isRestartRow = restartSnapshot.isNotEmpty;
          final rowId = controller.state.table2List[index].id;
          final isEyeRow = rowId != null && rowId != 0 && rowId == controller.state.currentTempIndex;
          final shuyingRaw = controller.state.table2List[index].colmunShuyingzhi?.toString() ?? '';
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
                    onTap: () => controller.juBuPingHeng(controller.state.table2List[index].id!),
                    child: controller.state.table2List[index].id != null &&
                            controller.state.table2List[index].id == controller.state.currentTempIndex
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
                                    "${controller.state.table2List[index].seq}",
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.0,
                                      fontWeight: FontWeight.w200,
                                      color: controller.state.isDarkMode ? Colors.white70 : Colors.black45,
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
                                "${controller.state.table2List[index].seq}",
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w200,
                                  color: controller.state.isDarkMode ? Colors.white70 : Colors.black45,
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
                        : () => controller.juBuPingHeng(controller.state.table2List[index].id!),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: !controller.state.isSeqVisible &&
                              controller.state.table2List[index].id != null &&
                              controller.state.table2List[index].id == controller.state.currentTempIndex
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
                  child: Row(
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
                              "${controller.state.table2List[index].colmunShuyingzhiD}",
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w200,
                                color: controller.state
                                    .getValueColor(controller.state.table2List[index].colmunShuyingzhiD.toString()),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (controller.state.table2List[index].colmunShuyingzhiD ?? '').isNotEmpty,
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
                        "${controller.state.table2List[index].columnXiazhujine}",
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
          final isZhengDa = controller.state.table2List[index].colmunShengfulu == '正打';
          final isLose = controller.state.table2List[index].colmunRemark?.startsWith('-') ?? false;
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
                      controller.juBuPingHeng(-1, v: controller.state.totalValue[29]);
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

  _buildLineChats() => GetBuilder<JiShuQiController>(
        builder: (controller) => controller.state.isBigRoad
            ? (controller.state.hasBigRoadData
                //大路子图
                ? GestureDetector(
                    onTap: () => controller.changeChart(),
                    child: Row(
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
                  )
                : const Text('暂无数据📊'))
            : (controller.state.chartData.isNotEmpty
                ? SizedBox(
                    height: 120,
                    child: Container(
                      color: controller.state.currentChartBgColor,
                      padding: const EdgeInsets.only(top: 8.0, right: 0.0, bottom: 8.0), // 去掉左边内边距
                      child: Builder(
                        builder: (context) {
                          return LineChart(
                            LineChartData(
                              backgroundColor: Colors.transparent,
                              borderData: FlBorderData(show: false),
                              //网格线显示和样式
                              gridData: FlGridData(
                                show: true,
                                // x轴线（横线）的间隔
                                horizontalInterval: (() {
                                  // 动态计算水平网格线间隔
                                  if (controller.state.chartData.isEmpty) return 1.0;
                                  final minV =
                                      controller.state.chartData.map((e) => e.sales).reduce((a, b) => a < b ? a : b) *
                                          0.9;
                                  final maxV =
                                      controller.state.chartData.map((e) => e.sales).reduce((a, b) => a > b ? a : b) *
                                          1.1;
                                  final span = maxV - minV;
                                  final step = span / 2.0;
                                  return (step.isFinite && step > 0) ? step : 1.0;
                                })(),
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
                                    reservedSize: 35, //离左边的距离
                                    interval: (() {
                                      if (controller.state.chartData.isEmpty) return 1.0;

                                      // 强制只显示3个标签：最小值、中间值、最大值
                                      // 使用动态间隔来避免标签重叠
                                      if (controller.state.chartData.isEmpty) return 1.0;

                                      final dataValues = controller.state.chartData.map((e) => e.sales).toList();
                                      final minValue = dataValues.reduce((a, b) => a < b ? a : b);
                                      final maxValue = dataValues.reduce((a, b) => a > b ? a : b);
                                      final span = maxValue - minValue;

                                      // 使用更大的间隔，但不要太大
                                      final step = span / 1.5; // 使用1.5倍间隔
                                      const minStep = 300.0; // 最小间隔300
                                      final finalStep = step > minStep ? step : minStep;

                                      debugPrint("---------------->$finalStep");
                                      return finalStep;
                                    })(),
                                    getTitlesWidget: (value, meta) {
                                      // 强制只显示3个标签：最小值、中间值、最大值
                                      if (controller.state.chartData.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      final dataValues = controller.state.chartData.map((e) => e.sales).toList();
                                      final minValue = dataValues.reduce((a, b) => a < b ? a : b);
                                      final maxValue = dataValues.reduce((a, b) => a > b ? a : b);
                                      final midValue = (minValue + maxValue) / 2;

                                      // 只显示最小值、中间值、最大值
                                      final tolerance = (maxValue - minValue) * 0.3; // 增加容差到30%，确保能匹配到标签
                                      final isMin = (value - minValue).abs() < tolerance;
                                      final isMax = (value - maxValue).abs() < tolerance;
                                      final isMid = (value - midValue).abs() < tolerance;

                                      if (!isMin && !isMax && !isMid) {
                                        return const SizedBox.shrink(); // 隐藏其他标签
                                      }

                                      return SideTitleWidget(
                                        meta: meta,
                                        space: 8,
                                        child: Text(
                                          _formatValue(value),
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.clip,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: controller.state.isDarkMode ? Colors.white : Colors.black87,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
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
                              minY: controller.state.chartData.isNotEmpty
                                  ? controller.state.chartData.map((e) => e.sales).reduce((a, b) => a < b ? a : b) * 0.9
                                  : 0,
                              maxY: controller.state.chartData.isNotEmpty
                                  ? controller.state.chartData.map((e) => e.sales).reduce((a, b) => a > b ? a : b) * 1.1
                                  : 100,
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
                                        const TextStyle(
                                          color: Colors.white,
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
    required String raw,
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
            onLongPress: () {
              switch (i) {
                case 1:
                  controller.showBottomFunction();
                  break;
                case 2:
                  // controller.lockScreen();
                  break;
              }
            },
            onPressed: () {
              switch (i) {
                case 1: //闲赢
                  controller.betRecordButton(1, 'table2');
                  break;
                case 2: //庄赢
                  controller.betRecordButton(2, 'table2');
                  break;
                case 3: //闲输
                  controller.betRecordButton(3, 'table2');
                  break;
                case 4: //庄输
                  controller.betRecordButton(4, 'table2');
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
                color: Colors.white,
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
