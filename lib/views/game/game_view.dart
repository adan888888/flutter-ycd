// ignore_for_file: prefer_const_constructors
import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
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
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: GestureDetector(
            // onLongPress: () => controller.lockScreen(),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () => controller.setRandom((int _) => debugPrint(_.toString())),
              child: Image.asset('assets/images/shai.png'),
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
                  backgroundColor:
                      controller.state.isBigRoad ? controller.state.bgColor : controller.state.chartBgColor,
                  title: Text(
                    "  $title ${GetStore.getInstance().userModel.nickname}",
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  )),
            ),
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //图表区
                _buildLineChats(),
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
                      horizontalInside: BorderSide(color: controller.state.lineColor, width: 0.5),
                      //垂直线
                      verticalInside: BorderSide(color: controller.state.lineColor, width: 0.5),
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
                        (i) => TableRow(
                            decoration: BoxDecoration(color: controller.state.bgColor),
                            children: List.generate(
                                4,
                                (index) => GestureDetector(
                                      onTap: () {
                                        if (index == 2) controller.juBuPingHeng(-1, v: controller.state.totalValue[30]);
                                      },
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Text(
                                              style: TextStyle(
                                                  height: 1.1 /*行高间距*/,
                                                  wordSpacing: 0 /*相当于padding*/,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w300,
                                                  color: ((i * 4 + index) == 26 || (i * 4 + index) == 27)
                                                      ? Colors.green
                                                      : ((i * 4 + index) == 24 || (i * 4 + index) == 22)
                                                          ? Colors.red
                                                          : (i * 4 + index) == 2 &&
                                                                  controller.state.currentTempIndex != 0
                                                              ? Colors.amber
                                                              : controller.state.textColor),
                                              controller.state.totalValue[i * 4 + index]),
                                        ),
                                      ),
                                    )).toList())).toList(),
                  ),
                ),
                //按钮功能区
                SizedBox(
                  height: 35,
                  child: Row(
                    children: [
                      _divier2(Colors.black, 38),
                      _buildButton(Colors.red, "P", 1),
                      _divier2(Colors.black, 38),
                      _buildButton(Colors.red, "B", 2),
                      _divier2(Colors.black, 38),
                      _buildButton(Colors.green, "P", 3),
                      _divier2(Colors.black, 38),
                      _buildButton(Colors.green, "B", 4),
                      _divier2(Colors.black, 38),
                      GestureDetector(
                          onTap: () {
                            controller.deleteLast();
                          },
                          child: SizedBox(
                              width: 65, child: Image.asset('assets/images/delete.png', width: 35, height: 35))),
                      Container(height: 25, width: 0.5, color: Colors.black),
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
                                color: controller.state.listViewColor,
                                child: EasyRefresh(
                                  controller: controller.refreshcontroller,
                                  // onRefresh: () async => controller.onRefresh(),
                                  onLoad: () async => controller.onLoadMore(), //不要onLoad就没有上拉加载更多
                                  child: ListView.separated(
                                    reverse: true,
                                    padding: const EdgeInsets.only(left: 6, right: 2),
                                    controller: controller.scrollController,
                                    itemCount: controller.state.table2ListX.length,
                                    itemBuilder: (BuildContext context, int index) => _buildItem(index),
                                    separatorBuilder: (BuildContext context, int index) => Divider(
                                        height: 2,
                                        indent: 5,
                                        thickness: 0.3,
                                        color: index % 2 == 0 ? Colors.red : Colors.black),
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
                      decoration: const InputDecoration(
                        icon: Icon(CupertinoIcons.ant_fill),
                        contentPadding: EdgeInsets.only(bottom: 7),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 1, color: Colors.blue)),
                        // border: OutlineInputBorder(borderSide: BorderSide(width: 5, color: Colors.red)),
                        // focusedBorder: OutlineInputBorder(borderSide: BorderSide(width: 1, color: Colors.blue)),
                        hintText: "请输入下注金额",
                        hintStyle: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildItem(int index) => SizedBox(
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //序号
            // GestureDetector(
            //   onTap: () => controller.juBuPingHeng(controller.state.table2ListX[index].id!),
            //   child: Container(
            //     color: controller.state.bgColor,
            //     width: 20,
            //     alignment: Alignment.centerRight,
            //     // child: Text("${controller.state.table2ListX[index].id}"),
            //     child: Text("${int.parse(controller.state.totalValue[1])-index}"),
            //   ),
            // ),
            //输赢
            GestureDetector(
              onTap: () =>
                  controller.juBuPingHeng(controller.state.table2ListX[index].id!, v: controller.state.totalValue[30]),
              child: Container(
                width: 70,
                alignment: Alignment.centerRight,
                child: Text(
                  controller.state.table2ListX[index].colmunShuyingzhi.toString(),
                  style: TextStyle(
                    color: controller.state.table2ListX[index].colmunShuyingzhi.toString().startsWith('-')
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                ),
              ),
            ),
            //消数
            SizedBox(
                width: 90,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(
                    "${controller.state.table2ListX[index].colmunShuyingzhiD}",
                    style: TextStyle(
                      color: controller.state.table2ListX[index].colmunShuyingzhiD.toString().startsWith('-')
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Visibility(
                    visible: controller.state.table2ListX[index].colmunShuyingzhiD!.isNotEmpty,
                    child: GestureDetector(
                        onTap: () => controller.updateLists(index),
                        child: Image.asset(height: 20, 'assets/images/delete.png')),
                  )
                ])),
            //下注值
            Container(
              width: 55,
              alignment: Alignment.centerRight,
              child: Text("${controller.state.table2ListX[index].columnXiazhujine}"),
            ),
            //胜负路
            _sflContainer(index),
          ],
        ),
      );

  _sflContainer(int index) => controller.state.table2ListX[index].colmunShengfulu == '正打'
      ? (controller.state.table2ListX[index].colmunRemark!.startsWith('-')
          ? Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 2),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 8),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 2),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            )
          : Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            ))
      : controller.state.table2ListX[index].colmunRemark!.startsWith('-')
          ? Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 8),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            )
          : Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  _divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
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
                                      color: Colors.grey.shade700,
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
                                borderColor: Colors.grey.shade300,
                                backgroundColor: Colors.white,
                                borderRadius: 0.0,
                                showBorder: true,
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
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        )
                      ],
                    ),
                  )
                : const Text('暂无数据📊'))
            : (controller.state.chartData.isNotEmpty
                ? SizedBox(
                    height: 100,
                    child: GestureDetector(
                      onTap: () => controller.changeChart(),
                      child: Container(
                        color: controller.state.chartBgColor,
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
                                            style: const TextStyle(
                                              color: Colors.white,
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
                  controller.recordButton(1, 'table2');
                  break;
                case 2: //庄赢
                  controller.recordButton(2, 'table2');
                  break;
                case 3: //闲输
                  controller.recordButton(3, 'table2');
                  break;
                case 4: //庄输
                  controller.recordButton(4, 'table2');
                  break;
              }
            },
            child: controller.state.isLoading
                ? const CupertinoActivityIndicator()
                : Text(
                    str,
                    style: const TextStyle(
                      color: Colors.black38,
                      fontWeight: FontWeight.bold,
                      height: 0,
                      fontSize: 18,
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
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
