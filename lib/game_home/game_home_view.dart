import 'dart:io';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:ycd/my_widget/baccarat_road_map.dart';
import 'package:ycd/utils/network/get_store.dart';

import 'game_home_logic.dart';

class GameHomePage extends GetView<GameHomeLogic> {
  const GameHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      dismissOnCapturedTaps: kIsWeb ? false : (Platform.isMacOS || Platform.isWindows ? false : true),
      child: Listener(
        onPointerDown: (PointerDownEvent event) {
          controller.onUserInteraction();
        },
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: GestureDetector(
            onLongPress: () => controller.lockScreen(),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              onPressed: () => controller.setRandom((int _) => debugPrint(_.toString())),
              child: Image.asset('assets/images/shai.png'),
            ),
          ),
          appBar: AppBar(
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
              backgroundColor: controller.state.chartBgColor,
              title: Text(
                "$title   ${GetStore.getInstance().userModel.nickname}",
                style: const TextStyle(fontSize: 12, color: Colors.white),
              )),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                //图表区
                buildChats(),
                //表格区统计区
                /* ColoredBox(
                  color: controller.state.lineColor,
                  child: SizedBox(
                    height: ((MediaQuery.of(context).size.width - 3) / 4) / MyState.height * 8 + 4,
                    width: double.infinity,
                    child: Obx(() => GridView.builder(
                          gridDelegate:  const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 0.5,
                            crossAxisSpacing: 0.5,
                            childAspectRatio: MyState.height,
                          ),
                          itemCount: controller.state.totalValue.length,
                          itemBuilder: (context, index) => Container(
                            alignment: Alignment.center,
                            color: controller.state.bgColor,
                            child: ColoredBox(
                                color: Colors.transparent,
                                child: Text(controller.state.totalValue[index],
                                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: controller.state.textColor))),
                          ),
                        )),
                  ),
                ),*/
                Obx(() => Table(
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
                        1: FlexColumnWidth(1),
                        0: IntrinsicColumnWidth(), //包裹内容
                        3: IntrinsicColumnWidth(),
                        2: FlexColumnWidth(1),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle, //垂直的位置
                      children: List.generate(
                          8,
                          (i) => TableRow(
                              decoration: BoxDecoration(color: controller.state.bgColor),
                              children: List.generate(
                                  4,
                                  (index) => GestureDetector(
                                        onTap: () {
                                          if (index == 2)
                                            controller.juBuPingHeng(-1, v: controller.state.totalValue[30]);
                                        },
                                        child: Center(
                                          child: Text(
                                              style: TextStyle(
                                                  height: 1.1,
                                                  //相当于padding
                                                  wordSpacing: 0,
                                                  fontSize: fontSize(i, index),
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
                                      )).toList())).toList(),
                    )),
                //按钮功能区
                SizedBox(
                  height: 35,
                  child: Row(
                    children: [
                      divier2(Colors.black, 38),
                      buildButton(Colors.red, "P", 1),
                      divier2(Colors.black, 38),
                      buildButton(Colors.red, "B", 2),
                      divier2(Colors.black, 38),
                      buildButton(Colors.green, "P", 3),
                      divier2(Colors.black, 38),
                      buildButton(Colors.green, "B", 4),
                      divier2(Colors.black, 38),
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
                  child: Obx(() => AbsorbPointer /*NotificationListener 也可以实现（监听滑动的回调）*/ (
                        absorbing: controller.state.isRefreshing.value,
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
                                itemBuilder: (BuildContext context, int index) => buildItem(index),
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

  double fontSize(int i, int index) => (i * 4 + index) == 15 ||
          (i * 4 + index) == 3 ||
          (i * 4 + index) == 20 ||
          (i * 4 + index) == 24 ||
          (i * 4 + index) == 16
      ? 10
      : 14;

  buildItem(int index) => SizedBox(
        height: 30,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                width: 100,
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(
                    "${controller.state.table2ListX[index].colmunShuyingzhiD}",
                    style: TextStyle(
                      color: controller.state.table2ListX[index].colmunShuyingzhiD.toString().startsWith('-')
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Visibility(
                    visible: controller.state.table2ListX[index].colmunShuyingzhiD!.isNotEmpty,
                    child: GestureDetector(
                        onTap: () {
                          controller.updateSqlite(index);
                        },
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
            sflContainer(index),
          ],
        ),
      );

  Container sflContainer(int index) => controller.state.table2ListX[index].colmunShengfulu == '正打'
      ? (controller.state.table2ListX[index].colmunRemark!.startsWith('-')
          ? Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 2),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 8),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 2),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            )
          : Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
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
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  const SizedBox(width: 8),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            )
          : Container(
              color: Colors.transparent,
              width: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const Text("1", style: TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                  const SizedBox(width: 8),
                  const Text("1", style: TextStyle(color: Colors.green)),
                  divier(Colors.grey.withValues(alpha: 0.5), 15),
                ],
              ),
            );

  buildChats() => Obx(
        () => controller.state.isMap.value
            ? (controller.state.listMap.isNotEmpty
                ? SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: GestureDetector(
                        onTap: () => controller.state.isMap.value = !controller.state.isMap.value,
                        onDoubleTap: () => controller.srollChange(),
                        child: BaccaratRoadMap(
                          results: controller.state.listMap,
                          scrollController: controller.scrollController1,
                        )),
                  )
                : const Text('data'))
            : (controller.state.chartData.isNotEmpty
                ? SizedBox(
                    height: 100,
                    child: GestureDetector(
                      onTap: () => controller.state.isMap.value = !controller.state.isMap.value,
                      child: Container(
                        color: controller.state.chartBgColor,
                        padding: const EdgeInsets.only(top: 8.0, right: 0.0, bottom: 8.0), // 去掉左边内边距
                        child: Builder(
                          builder: (context) {
                            return LineChart(
                              LineChartData(
                                backgroundColor: Colors.transparent,
                                borderData: FlBorderData(show: false), // 无边框
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: (() {
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
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.white.withOpacity(0.3),
                                      strokeWidth: 1,
                                      dashArray: [5, 5], // 虚线样式
                                    );
                                  },
                                  verticalInterval: 1, // 设置一个很小的值，但不显示垂直网格线
                                  getDrawingVerticalLine: (value) {
                                    return const FlLine(
                                      color: Colors.transparent, // 透明色，实际上不显示
                                      strokeWidth: 0,
                                    );
                                  },
                                ),
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
                                      reservedSize: 40,
                                      interval: (() {
                                        if (controller.state.chartData.isEmpty) return 1.0;
                                        final minV = controller.state.chartData
                                                .map((e) => e.sales)
                                                .reduce((a, b) => a < b ? a : b) *
                                            0.9;
                                        final maxV = controller.state.chartData
                                                .map((e) => e.sales)
                                                .reduce((a, b) => a > b ? a : b) *
                                            1.1;
                                        final span = maxV - minV;
                                        final step = span / 2.0;
                                        return (step.isFinite && step > 0) ? step : 1.0;
                                      })(),
                                      getTitlesWidget: (value, meta) {
                                        // 简单显示所有由fl_chart生成的标签
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 4,
                                          child: Text(
                                            _formatValue(value),
                                            maxLines: 1,
                                            softWrap: false,
                                            overflow: TextOverflow.clip,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
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
                                            dotColor = const Color(0xFF10B981); // 绿色 - 资金增加
                                          } else if (change < 0) {
                                            dotColor = const Color(0xFFEF4444); // 红色 - 资金减少
                                          } else {
                                            dotColor = const Color(0xFF6B7280); // 灰色 - 无变化
                                          }
                                        }
                                        return FlDotCirclePainter(
                                          radius: 3,
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

  Container divier(Color color, double height) => Container(height: height, width: 1, color: color);

  Container divier2(Color color, double height) => Container(height: height, width: 5, color: Colors.transparent);

  buildButton(Color bg, String str, int i) => Expanded(
        child: SizedBox(
          height: 32,
          child: TextButton(
            style: buildButtonStyle(bg),
            onLongPress: () {
              switch (i) {
                case 1:
                  controller.showBottomFunction();
                  break;
                case 2:
                  controller.lockScreen();
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

  String _formatValue(double value) {
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

  buildButtonStyle(Color bg) => ButtonStyle(
        backgroundColor: WidgetStateProperty.all(bg),
        overlayColor: WidgetStateProperty.all(Colors.red.shade100),
        padding: WidgetStateProperty.all(EdgeInsetsGeometry.lerp(EdgeInsets.zero, EdgeInsets.zero, 0)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0), // 设置圆角大小
          ),
        ),
      );
}

// Expanded(child: Container(height: double.infinity, color:controller.state.bgColor, child: Text(text, textAlign: TextAlign.center)));

class SinglePicker extends StatefulWidget {
  const SinglePicker({super.key});

  @override
  State<StatefulWidget> createState() => _SinglePickerState();
}

class _SinglePickerState extends State<SinglePicker> {
  final controller = Get.find<GameHomeLogic>();
  int selectIndex = 0;

  @override
  void initState() {
    selectIndex = controller.state.selectIndex.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.functionConfirm(selectIndex);
                },
                style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.transparent)),
                child: const Text(
                  "确定",
                  style: TextStyle(color: Colors.redAccent, fontSize: 20),
                ),
              ),
            ],
          ),
          Obx(() => Expanded(
                child: CupertinoPicker(
                    scrollController: controller.fixedExtentScrollController,
                    itemExtent: 50, // 每个选项的高度
                    onSelectedItemChanged: (int index) {
                      // 处理选中项的变化
                      selectIndex = index;
                    },
                    children: List.generate(
                      controller.state.functionTypes.length,
                      (index) => Align(
                        alignment: Alignment.center,
                        child: Text(controller.state.functionTypes[index].toString()),
                      ),
                    )),
              ))
        ],
      ),
    );
  }
}
