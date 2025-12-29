import 'package:flutter/material.dart';

/// 百家乐大路图组件
/// 可复用的独立组件，供其他模块使用
class BaccaratBigRoadWidget extends StatelessWidget {
  /// 大路图数据 (6行 x N列的二维数组)
  final List<List<String>> bigRoadData;

  /// 单元格宽度
  final double cellWidth;

  /// 单元格高度
  final double cellHeight;

  /// 是否有数据（用于判断是否显示滚动条）
  final bool hasData;

  /// 滚动控制器（可选）
  final ScrollController? scrollController;

  /// 边框颜色
  final Color borderColor;

  /// 背景颜色
  final Color? backgroundColor;

  /// 圆角半径
  final double borderRadius;

  /// 是否显示边框
  final bool showBorder;

  final String front;

  final String back;

  const BaccaratBigRoadWidget({
    super.key,
    required this.bigRoadData,
    this.cellWidth = 20.0,
    this.cellHeight = 20.0,
    this.hasData = false,
    this.scrollController,
    this.borderColor = Colors.grey,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.showBorder = true,
    this.front = "b",
    this.back = "p",
  });

  @override
  Widget build(BuildContext context) {
    // 构建大路图内容
    Widget bigRoadContent = Column(
      children: bigRoadData
          .map(
            (row) => Row(
              children: row
                  .map(
                    (cell) => Container(
                      width: cellWidth,
                      height: cellHeight,
                      decoration: BoxDecoration(
                        border: showBorder
                            ? Border.all(
                                color: borderColor.withValues(alpha: 0.3),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: cell.isEmpty ? null : _buildBigRoadItem(cell, front, back),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showBorder ? Border.all(color: borderColor, width: 1) : null,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: hasData
          ? SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: bigRoadContent,
            )
          : Center(child: bigRoadContent), // 没有数据时居中显示
    );
  }

  /// 构建大路图项
  Widget _buildBigRoadItem(String winner, String front, String back) {
    Color color;
    String text;

    switch (winner) {
      case '闲家':
        color = Colors.green;
        text = back;
        break;
      case '庄家':
        color = Colors.red;
        text = front;
        break;
      default:
        color = Colors.grey;
        text = '?';
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// 大路图配置类
class BaccaratBigRoadConfig {
  final double cellWidth;
  final double cellHeight;
  final Color borderColor;
  final Color? backgroundColor;
  final double borderRadius;
  final bool showBorder;
  final Color playerColor;
  final Color bankerColor;
  final String playerText;
  final String bankerText;

  const BaccaratBigRoadConfig({
    this.cellWidth = 20.0,
    this.cellHeight = 20.0,
    this.borderColor = Colors.grey,
    this.backgroundColor,
    this.borderRadius = 8.0,
    this.showBorder = true,
    this.playerColor = Colors.blue,
    this.bankerColor = Colors.red,
    this.playerText = 'P',
    this.bankerText = 'B',
  });
}

/// 带配置的大路图组件
class BaccaratBigRoadWidgetWithConfig extends StatelessWidget {
  final List<List<String>> bigRoadData;
  final bool hasData;
  final ScrollController? scrollController;
  final BaccaratBigRoadConfig config;

  const BaccaratBigRoadWidgetWithConfig({
    super.key,
    required this.bigRoadData,
    this.hasData = false,
    this.scrollController,
    this.config = const BaccaratBigRoadConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return BaccaratBigRoadWidget(
      bigRoadData: bigRoadData,
      cellWidth: config.cellWidth,
      cellHeight: config.cellHeight,
      hasData: hasData,
      scrollController: scrollController,
      borderColor: config.borderColor,
      backgroundColor: config.backgroundColor,
      borderRadius: config.borderRadius,
      showBorder: config.showBorder,
    );
  }
}
