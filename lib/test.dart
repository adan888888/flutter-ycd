import 'package:flutter/material.dart';

import 'my_widget/baccarat_road_map.dart';

void main() {
  // 模拟大路图数据：B表示庄，P表示闲
  final List<String> results = [
    "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    "B", "P", "B", "P", "B", "P", // 庄闲交替
    "B", "B", "P", "P", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    "B", "P", "B", "P", "B", "P", // 庄闲交替
    "B", "B", "P", "P", "B", "B", // 规则混合
    "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    "B", "P", "B", "P", "B", "P", // 庄闲交替
    "B", "B", "P", "P", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", "B", // 庄连续超过6个  8个
    "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", "P", // 闲连续  6个
    "B", "P", "B", "P", "B", "P", // 庄闲交替
    "B", "B", "P", "P", "B", "B", // 规则混合
  ];
  runApp(MaterialApp(
    home: Center(
      child: BaccaratRoadMap(
        results: results,
      ),
    ),
  ));
}
