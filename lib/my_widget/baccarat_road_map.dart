import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/request/request.dart';

class BaccaratRoadMap extends StatefulWidget {
  final List<String> results;

  const BaccaratRoadMap({required this.results, super.key});

  @override
  _BaccaratRoadMapState createState() => _BaccaratRoadMapState(results);
}

class _BaccaratRoadMapState extends State<BaccaratRoadMap> {
  final ScrollController _scrollController = ScrollController();
  final List<String> results;

  _BaccaratRoadMapState(this.results);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // 使用 ClampingScrollPhysics，滚动到边缘时停止
        // physics: const ClampingScrollPhysics(),
        controller: _scrollController,
        child: CustomPaint(
          size: Size(results.length * 5.0, 95), // 动态宽度
          painter: RoadMapPainter(results, _scrollController),
        ),
      ),
    );
  }
}

class RoadMapPainter extends CustomPainter {
  final List<String> results;
  final double cellSize = 15.0; // 每个单元格大小
  final int maxRows = 6; // 最大行数
  final ScrollController scrollController;

  RoadMapPainter(this.results, this.scrollController);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 解析结果生成绘图坐标
    final positions = _generatePositions(results);

    for (final pos in positions) {
      final offset = Offset(pos['x'] * cellSize, pos['y'] * cellSize);

      if (pos['type'] == 'B') {
        paint.color = Colors.red; // 庄：红色
      } else if (pos['type'] == 'P') {
        paint.color = Colors.blue; // 闲：蓝色
      }

      canvas.drawCircle(offset + Offset(cellSize / 2, cellSize / 2), cellSize / 2 - 2, paint);
    }
    // _scrollToEnd(scrollController);
  }

  void _scrollToEnd(ScrollController _scrollController) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent-50,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  /// 根据规则生成大路图坐标
  List<Map<String, dynamic>> _generatePositions(List<String> results) {
    List<Map<String, dynamic>> positions = [];
    int currentColumn = 0; // 当前列（是给底用的）
    int currentRow = 0; // 当前行
    String? lastType; // 上一个结果类型
    int currentColumn1 = 0; // 换列的次数

    for (final result in results) {
      if (lastType == null) {
        // 初始状态：第一个元素
        currentColumn = 0;
        currentRow = 0;
        currentColumn1 = 0;
        positions.add({'x': currentColumn, 'y': currentRow, 'type': result});
      } else if (result == lastType) {
        // 同类型，向下绘制2
        if (currentRow < maxRows - 1 && !ifHaveValue(currentRow + 1, currentColumn, positions) /*判断这个点上有没有画圈*/) {
          currentRow++;
          // if (ifHaveValue(currentRow + 1, currentColumn, positions)) {
          //   currentColumn++;
          // } else {
          //   currentRow++;
          // }
        } else {
          // 超过最大行数，在底部延续(主要用于超过6还在连续的底部的换列)
          currentColumn++;
        }
        positions.add({'x': currentColumn, 'y': currentRow, 'type': result});
      } else {
        // 不同类型，换列
        currentColumn1++;
        currentColumn = currentColumn1; //不同类型的时候再把真的列数恢复过来
        currentRow = 0;
        // 保存当前点的绘图位置
        positions.add({'x': currentColumn1, 'y': currentRow, 'type': result});
      }

      lastType = result; // 更新上一个类型
    }

    return positions;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  ifHaveValue(int currentRow, int currentColumn, List<Map<String, dynamic>> positions) {
    for (var value in positions) {
      if (value['x'] == currentColumn && value['y'] == currentRow) {
        return true;
      }
    }
    return false;
  }
}
