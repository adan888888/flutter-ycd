// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:ycd/model/linechart_data_model.dart';
import 'package:ycd/my_db/table1_model.dart';
import 'package:ycd/my_db/table2_model.dart';

class GameState {
  var ratio = 50; //庄闲占比(50=50%庄 50%闲；70=70%庄 30%闲，)
  static const OFFSET8431 = 8431; //庄闲占比是 庄60% 闲40%
  static const double height = 16 / 3;
  int LockScreenTime = 12; //锁屏时间（分钟）
  var isLoading = false;
  var isCanPress = true;
  var randomValue = ''; //随机的出来的庄闲
  var bettingMoney = '';
  var js1 = 0; //随机总数
  var js2 = 0;
  int currentTempIndex = 0; //局部平衡的临时变量
  var lineColor = Colors.black87.withValues(alpha: 0.8);
  var listViewColor = const Color(0xFFE8F5E9); // 浅绿豆沙色
  var bgColor = const Color(0xFFE9EEDB);
  var chartBgColor = const Color(0xFFE8F5E9); //图表背景（浅绿豆沙色）
  var textColor = Colors.black;

  // 暗黑主题标志
  var isDarkMode = false;

  // 图表显示标志
  var isChartVisible = true;

  // 暗黑主题颜色（深蓝色调风格）
  var darkLineColor = Colors.white.withValues(alpha: 0.6);
  var darkListViewColor = const Color(0xFF1A2332); // 深蓝灰色
  var darkBgColor = const Color(0xFF1E2A3A); // 深蓝色
  var darkChartBgColor = const Color(0xFF15202B); // 深蓝黑色
  var darkTextColor = Colors.white; // 暗黑模式下使用纯白色文字

  // 根据主题获取颜色
  Color get currentLineColor => isDarkMode ? darkLineColor : lineColor;

  Color get currentListViewColor => isDarkMode ? darkListViewColor : listViewColor;

  Color get currentBgColor => isDarkMode ? darkBgColor : bgColor;

  Color get currentChartBgColor => isDarkMode ? darkChartBgColor : chartBgColor;

  Color get currentTextColor => isDarkMode ? darkTextColor : textColor;
  var totalValue /*统计区*/ = <String>[];
  var chartData /*图表数据*/ = <LineChartDataModel>[];

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
  var isBigRoad = true;

  // ***********== 大路图相关常量定义 ***********==
  /// 大路图行数
  static const int bigRoadRows = 6;

  /// 大路图列数
  static const int bigRoadCols = 1200;

  /// 每个格子的宽度（像素）
  static const double cellWidth = 15.0;

  /// 当前开奖结果文本（如：闲家胜 (8 vs 6)）
  String currentResult = '';

  /// 本局获胜者（闲家/庄家/和局）
  String winner = '';

  // ***********== 历史记录和路子图 ***********==
  /// 游戏历史记录列表（最多保存20局）
  List<Map<String, dynamic>> gameHistory = [];

  /// 大路图数据（58行${bigRoadCols}列的二维数组）
  List<List<String>> bigRoad = [];

  // ***********== 大路图状态 ***********==
  /// 当前大路图行位置（0-5）
  int currentRow = 0;

  /// 当前大路图列位置（0-119）
  int currentCol = 0;

  /// 上一局的获胜者（用于判断大路图绘制规则）
  String lastWinner = '';

  /// 当前列是否已填满6行
  bool currentColumnFull = false;

  /// 长龙开始的列（用于长龙结束后确定下一个不同结果的起始位置）
  int dragonStartCol = -1;

  /// 长龙平行绘制的行位置（当长龙开始向右平行绘制时记录）
  int dragonParallelRow = -1;
  int recordRowFirst = 0; //记录横向的次数
  int recordRightCol = 0; //记录横向时候的

  /// 构造函数
  /// 初始化大路图数据
  GameState() {
    initializeBigRoad();
  }

  /// 初始化大路图
  /// 创建6行120列的空大路图，重置所有位置状态
  void initializeBigRoad() {
    debugPrint("------>initializeBigRoad");
    bigRoad = List.generate(bigRoadRows, (index) => List.generate(bigRoadCols, (index) => ''));
    currentRow = 0;
    currentCol = 0;
    lastWinner = '';
    currentColumnFull = false;
    dragonStartCol = -1; // 重置长龙开始列
    dragonParallelRow = -1; // 重置长龙平行绘制行
  }

  /// 检查大路图是否有数据
  /// 返回true表示大路图中有任何非空数据
  bool get hasBigRoadData {
    bool hasData = bigRoad.any((row) => row.any((cell) => cell.isNotEmpty));
    return hasData;
  }
}
