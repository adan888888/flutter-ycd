// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ycd/my_widget/baccarat_big_road_widget.dart';
import 'package:ycd/utils/network/get_store.dart';

import '../../my_widget/vertical_text.dart';
import 'game_controller.dart';
import 'game_state.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: kIsWeb ? false : (Platform.isMacOS || Platform.isWindows ? false : true),
      child: Listener(
        onPointerDown: (PointerDownEvent event) => controller.onUserInteraction(),
        onPointerMove: (event) => controller.onUserInteraction(),
        child: GetBuilder<GameController>(
          builder: (controller) => Scaffold(
            backgroundColor: controller.state.currentBgColor,
            floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
            floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
            floatingActionButton: Transform.scale(
              scale: 0.7,
              child: GetBuilder<GameController>(
                builder: (controller) {
                  return AnimatedScale(
                    scale: controller.state.floatButtonScale,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: FloatingActionButton(
                      backgroundColor: Colors.transparent,
                      onPressed: () {
                        // 触发点击动画：放大1.5倍再缩小
                        controller.state.floatButtonScale = 1.5;
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
              child: GetBuilder<GameController>(
                builder: (controller) => AppBar(
                    // 隐藏返回键
                    automaticallyImplyLeading: false,
                    actions: [
                      GestureDetector(
                          onTap: () => controller.toggleDarkMode(),
                          child: Icon(
                            controller.state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            size: 20,
                            color: Colors.white,
                          )),
                      GestureDetector(
                          onTap: () => controller.lockScreen(),
                          child: const Icon(
                            Icons.lock,
                            size: 20,
                            color: Colors.white,
                          )),
                      GestureDetector(
                          onTap: () => controller.showBottomFunction(),
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
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
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    )),
              ),
            ),
            body: SafeArea(
              child: GetBuilder<GameController>(
                builder: (controller) => LayoutBuilder(
                  builder: (context, constraints) {
                    // 获取图表区域的高度（如果显示）
                    double? chartHeight;
                    if (controller.state.isChartVisible) {
                      // 折线图固定高度120，大路图需要动态计算
                      chartHeight = controller.state.isBigRoad ? null : 120.0;
                    }

                    return Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            //图表区
                            controller.state.isChartVisible ? _buildLineChats() : const SizedBox.shrink(),
                            SizedBox(height: 5),
                            //表格区统计区
                            GetBuilder<GameController>(
                              builder: (controller) => Table(
                                border: TableBorder(
                                  //在右上下的边框线
                                  // top: BorderSide(color: Colors.red),
                                  // left: BorderSide(color: Colors.red),
                                  // right: BorderSide(color: Colors.red),
                                  // bottom: BorderSide(color: Colors.red),
                                  //水平线
                                  horizontalInside: BorderSide(color: controller.state.currentLineColor, width: 0.1),
                                  //垂直线
                                  verticalInside: BorderSide(color: controller.state.currentLineColor, width: 1),
                                ),
                                //单元格的宽， map哪列 ：宽度
                                columnWidths: const {
                                  1: FlexColumnWidth(1.3),
                                  // 0: IntrinsicColumnWidth(), //包裹内容
                                  0: FlexColumnWidth(1),
                                  3: FlexColumnWidth(1),
                                  2: FlexColumnWidth(1.3),
                                },
                                //垂直的位置
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: List.generate(
                                    8,
                                    (row) => TableRow(
                                        decoration: BoxDecoration(color: controller.state.currentBgColor),
                                        children: List.generate(4, (column) {
                                          final cellWidget = GestureDetector(
                                            onTap: () {
                                              // 仅第一行第三列可点：取消局部平衡（currentTempIndex 置 0，眼睛同步消失）
                                              if (row == 0 && column == 2) {
                                                controller.juBuPingHeng(-1, v: controller.state.totalValue[30]);
                                              }
                                            },
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: Text(
                                                    style: TextStyle(
                                                        height: 1.3 /*行高间距*/,
                                                        wordSpacing: 0 /*相当于padding*/,
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w400,
                                                        color: ((row * 4 + column) == 26 || (row * 4 + column) == 27)
                                                            ? Colors.green
                                                            : ((row * 4 + column) == 24 || (row * 4 + column) == 22)
                                                                ? (controller.state.isDarkMode
                                                                    ? Colors.orange
                                                                    : Colors.red)
                                                                : (row * 4 + column) == 2 &&
                                                                        controller.state.currentTempIndex != 0
                                                                    ? Colors.amber
                                                                    : controller.state.currentTextColor),
                                                    controller.state.totalValue[row * 4 + column]),
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
                              ),
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
                                    onPressed: () => controller.deleteLast(),
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: controller.state.isDarkMode ? Colors.white70 : Colors.black45,
                                      ),
                                    ),
                                  ),
                                  Container(height: 25, width: 0.5, color: controller.state.currentTextColor),
                                  GestureDetector(
                                    onTap: controller.reStart,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                                      child: Image.asset(height: 35, width: 35, 'assets/images/restart3.png'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            //列表
                            Expanded(
                              child: GetBuilder<GameController>(
                                  builder: (controller) => AbsorbPointer /*NotificationListener 也可以实现（监听滑动的回调）*/ (
                                        absorbing: controller.state.isRefreshing,
                                        child: GestureDetector(
                                          // onLongPress: () => controller.lockScreen(),
                                          child: ColoredBox(
                                            color: controller.state.currentListViewColor,
                                            child: EasyRefresh(
                                              controller: controller.refreshcontroller,
                                              // onRefresh: () async => controller.onRefresh(),
                                              onLoad: () async => controller.onLoadMore(), //不要onLoad就没有上拉加载更多
                                              child: ListView.builder(
                                                reverse: true,
                                                padding: const EdgeInsets.all(10),
                                                controller: controller.scrollController,
                                                itemCount: controller.state.table2List.length,
                                                itemBuilder: (BuildContext context, int index) => _buildItem(index),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                            ),
                            //输入金额
                            SafeArea(
                              bottom: true,
                              child: SizedBox(
                                height: 40,
                                child: Row(
                                  children: [
                                    SizedBox(width: 3),
                                    GestureDetector(
                                      onTap: () => controller.sort(),
                                      child: Icon(
                                        CupertinoIcons.ant_fill,
                                        color: controller.state.currentTextColor,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          textSelectionTheme: TextSelectionThemeData(
                                            selectionColor: controller.state.isDarkMode
                                                ? Colors.white.withValues(alpha: 0.4) // 暗色模式：更亮的半透明白色选中背景
                                                : Colors.blue.withValues(alpha: 0.3), // 亮色模式：半透明蓝色选中背景
                                            selectionHandleColor: controller.state.isDarkMode
                                                ? Colors.white // 暗色模式：白色选择手柄
                                                : Colors.blue, // 亮色模式：蓝色选择手柄
                                          ),
                                        ),
                                        child: TextField(
                                          focusNode: controller.focusNode,
                                          autofocus: false,
                                          controller: controller.textEditingController,
                                          onChanged: (value) {},
                                          //表示基础类型是数字键盘，主要用于输入数字, decimal设置为 true 时，允许输入小数
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          // ignorePointers: false,//是否可以用虚拟键盘
                                          //过滤（仅只能输入数字，不能小数点.）
                                          // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          //限制只能输入数字
                                          textInputAction: TextInputAction.done,
                                          // 通过输入格式化器限制只能输入数字和小数点
                                          inputFormatters: [
                                            // 允许 0-9 数字和小数点（.）
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                          ],
                                          cursorColor: controller.state.isDarkMode ? Colors.white : Colors.blue,
                                          // 暗色模式：白色光标，亮色模式：蓝色光标
                                          style: TextStyle(color: controller.state.currentTextColor),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.only(bottom: 7),
                                            focusedBorder: UnderlineInputBorder(
                                                borderSide: BorderSide(width: 1, color: Colors.blue)),
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
                            )
                          ],
                        ),
                        // 悬浮按钮：切换图表显示/隐藏（叠加在图表和统计区之间）
                        if (controller.state.isChartVisible)
                          Positioned(
                            top: chartHeight != null
                                ? chartHeight - 20 // 折线图：图表高度120，按钮高度40，居中在图表底部
                                : 80 - 20, // 大路图：估算高度80（标题行约30px + 大路图约50px），按钮居中在图表底部
                            left: 0,
                            right: 0,
                            child: Center(
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
                            ),
                          )
                        else
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Center(
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
                                    Icons.keyboard_arrow_down,
                                    color: controller.state.isDarkMode
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.black.withValues(alpha: 0.4),
                                    size: 20,
                                  ),
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
      ),
    );
  }

  _buildItem(int index) => GetBuilder<GameController>(
        builder: (controller) {
          // 由于ListView是reverse的，需要转换index来获取正确的交替颜色
          final actualIndex = controller.state.table2List.length - 1 - index;
          // 根据index的奇偶性设置不同的背景色
          final backgroundColor = actualIndex % 2 == 0
              ? (controller.state.isDarkMode
                  ? const Color(0xFF243447) // 深蓝灰色（稍浅）
                  : Colors.grey.shade50) // 浅灰白色
              : (controller.state.isDarkMode
                  ? const Color(0xFF1E2A3A) // 深蓝色（与背景色一致）
                  : Colors.grey.shade100); // 稍深一点的浅灰色

          return Container(
            height: 30,
            color: backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 标记+序号：固定列宽；数字过长时缩小字体（与下注列一致）
                GestureDetector(
                  onTap: () => controller.juBuPingHeng(controller.state.table2List[index].id!),
                  child: controller.state.table2List[index].id != null &&
                          controller.state.table2List[index].id == controller.state.currentTempIndex
                      ? SizedBox(
                          width: GameState.seqColMaxWidth,
                          child: Center(
                            child: Icon(
                              Icons.visibility,
                              size: 16,
                              color: controller.state.isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800,
                            ),
                          ),
                        )
                      : SizedBox(
                          width: GameState.seqColMaxWidth,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Text(
                                "${controller.state.table2List[index].seq}",
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w300,
                                  color: controller.state
                                      .getValueColor(controller.state.table2List[index].colmunShuyingzhi.toString()),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

                // 输赢列：固定列宽；过长缩小字体
                GestureDetector(
                  onTap: () => controller.juBuPingHeng(controller.state.table2List[index].id!,
                      v: controller.state.totalValue[30]),
                  child: SizedBox(
                    width: GameState.betColWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          controller.state.table2List[index].colmunShuyingzhi.toString(),
                          maxLines: 1,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: controller.state
                                .getValueColor(controller.state.table2List[index].colmunShuyingzhi.toString()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 消数列：固定列宽；数字区过长缩小字体，右侧保留删除图标
                SizedBox(
                  width: GameState.betColWidth,
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
                  width: GameState.betColWidth,
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
              ],
            ),
          );
        },
      );

  _sflContainer(int index) => GetBuilder<GameController>(
        builder: (controller) {
          final isZhengDa = controller.state.table2List[index].colmunShengfulu == '正打';
          final isLose = controller.state.table2List[index].colmunRemark?.startsWith('-') ?? false;
          final dividerColor = controller.state.isDarkMode ? Colors.white24 : Colors.grey.withValues(alpha: 0.5);

          if (isZhengDa) {
            if (isLose) {
              return Container(
                color: Colors.transparent,
                width: GameState.sflColWidth,
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
                width: GameState.sflColWidth,
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
                width: GameState.sflColWidth,
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
                width: GameState.sflColWidth,
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

  _buildLineChats() => GetBuilder<GameController>(
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
                                cellWidth: GameState.cellWidth,
                                cellHeight: GameState.cellWidth,
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
                    child: GestureDetector(
                      onTap: () => controller.changeChart(),
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
                                    ? controller.state.chartData.map((e) => e.sales).reduce((a, b) => a < b ? a : b) *
                                        0.9
                                    : 0,
                                maxY: controller.state.chartData.isNotEmpty
                                    ? controller.state.chartData.map((e) => e.sales).reduce((a, b) => a > b ? a : b) *
                                        1.1
                                    : 100,
                                // 设置图表边距
                                clipData: const FlClipData.none(),
                                // 添加一些内边距
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  handleBuiltInTouches: true,
                                  touchTooltipData: LineTouchTooltipData(
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
                                    isCurved: true,
                                    color: Colors.white,
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
                                            dotColor = Colors.red; // 红色 - 资金增加
                                          } else if (change < 0) {
                                            dotColor = Colors.green; // 绿色 - 资金减少
                                          } else {
                                            dotColor = const Color(0xFF6B7280); // 灰色 - 无变化
                                          }
                                        }
                                        return FlDotCirclePainter(
                                          radius: 2.3,
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
                    ),
                  )
                : const Text('data')),
      );

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
                  controller.betBecordButton(1, 'table2');
                  break;
                case 2: //庄赢
                  controller.betBecordButton(2, 'table2');
                  break;
                case 3: //闲输
                  controller.betBecordButton(3, 'table2');
                  break;
                case 4: //庄输
                  controller.betBecordButton(4, 'table2');
                  break;
              }
            },
            child: controller.state.isLoading
                ? const CupertinoActivityIndicator()
                : Text(
                    str,
                    style: TextStyle(
                      color: (i == 1 || i == 2)
                          ? (controller.state.isDarkMode ? Colors.orange : Colors.red) // P+ 和 B+ 使用橙色（暗黑）或红色（亮色）
                          : (controller.state.isDarkMode ? Colors.green : Colors.green), // P- 和 B- 使用绿色（两种模式都是绿色）
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
        overlayColor: WidgetStateProperty.all(Colors.red.shade100),
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
