// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import '../my_db/table1_model.dart';
import '../my_db/table2_model.dart';

class GameState {
  static const OFFSET8431 = 8431; //庄闲占比是 庄60% 闲40%
  static const double height = 16 / 3;
  var isLoading = false;
  var isCanPress = true;
  var randomValue = ''; //随机的出来的庄闲
  var bettingMoney = '';
  var js1 = 0; //随机总数
  var js2 = 0;
  int currentTempIndex = 0;
  var lineColor = Colors.black87.withValues(alpha: 0.8);
  var listViewColor = const Color(0xFFE9EEDB);
  var bgColor = const Color(0xFFE9EEDB);
  var chartBgColor = Colors.black; //图表背景
  var textColor = Colors.black;
  var totalValue /*统计区*/ = <String>[];
  var chartData /*图表数据*/ = <SalesData>[];

  // List<SalesData> chartData/*图表数据*/ = List.generate(70, (index) =>SalesData(index.toString(),Random().nextInt(1).toDouble() )).toList().obs;

  var table1List = <Table1Model>[];
  // var table2List = <Table2Model>[];
  var table2ListX = <Table2Model>[];

  var selectIndex = 7;
  var functionTypes = [
    '1.排列数据',
    '2.消除数据',
    '3.修改本金',
    '4.修改位置',
    '5.删除本页',
    '6.重置流水',
    '7.备份数据',
    '8.重启系统',
    '9.修改期望值',
    '10.恢复数据',
    '11.修改赔率',
    '12.退出程序'
  ];

  var isRefreshing = false;
  var listMap = <String>[]; //路子图数据
  var isMap = false;

  /// 大路图行数
  static const int bigRoadRows = 6;

  /// 大路图列数
  static const int bigRoadCols = 120;

  /// 每个格子的宽度（像素）
  static const double cellWidth = 20.0;

  /// 大路图数据（6行120列的二维数组）
  var bigRoad = <List<String>>[];
}

class SalesData {
  SalesData(this.year, this.sales);

  int year;
  double sales;

  @override
  String toString() {
    return '{$sales}';
  }
}
