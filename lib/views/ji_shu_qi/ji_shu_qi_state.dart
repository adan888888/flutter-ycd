// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:ycd/model/linechart_data_model.dart';
import 'package:ycd/my_db/table1_model.dart';
import 'package:ycd/my_db/table2_model.dart';

class JiShuQiState {
  var ratio = 50; //庄闲占比(50=50%庄 50%闲；70=70%庄 30%闲，)
  static const OFFSET8431 = 8431; //庄闲占比是 庄60% 闲40%
  static const double height = 16 / 3;
  int LockScreenTime = 5; //锁屏时间（分钟）
  var isLoading = false;
  var isCanPress = true;
  var randomValue = ''; //随机的出来的庄闲
  var floatButtonScale = 1.0; // 浮动按钮缩放比例，用于点击动画
  var bettingMoney = '';
  var js1 = 0; //随机总数
  var js2 = 0;
  int currentTempIndex = 0; // 局部平衡锚点行 id（与列表眼睛一致）；持久化为服务端 table1.temp_index → Table1Model.tempIndex

  /// 列表各列固定宽度（ji_shu_qi_view 投注记录行；过长用 FittedBox 缩小字体）
  static const double seqColMaxWidth = 34; // 序号+眼睛，约 4 个数字
  static const double sflColWidth = 32; // 胜负路固定宽
  /// 下注列：约 5 个数字宽度；超出时用 FittedBox 缩小字体（同统计区）
  static const double betColWidth = 45;

  /// 投注记录表每一行高度（与 ji_shu_qi_view._buildItem 一致，用于顶部插入后恢复滚动位置）
  static const double bettingTableRowHeight = 26;

  /// 统计区固定高度（吸顶 SliverPersistentHeader）
  static const double statsAreaHeight = 145;

  var lineColor = Colors.black87.withValues(alpha: 0.8);
  var listViewColor = Colors.grey.shade50; // 浅灰白色
  var bgColor = Colors.grey.shade50; // 浅灰白色
  var chartBgColor = Colors.grey.shade50; // 图表背景（浅灰白色）
  var textColor = Colors.black;

  // 暗黑主题标志
  var isDarkMode = true;

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

  // 列表列颜色（输赢值、消数值、胜负路共用）
  /// 负数/输的字体颜色（白天模式：绿色，暗黑模式：0xFF69B6AD）
  Color get negativeColor => isDarkMode ? const Color(0xFF69B6AD) : Colors.green;

  /// 正数/赢的字体颜色（白天模式：红色，暗黑模式：橙色）
  Color get positiveColor => isDarkMode ? Colors.orange : Colors.red;

  /// 根据值判断字体颜色（负数返回绿色/0xFF69B6AD，正数返回红色/橙色）
  Color getValueColor(String value) {
    return value.startsWith('-') ? negativeColor : positiveColor;
  }

  // 按钮颜色（P+/B+ 和 P-/B-）
  /// P+ 和 B+ 按钮背景颜色（暗黑模式：深蓝绿色，白色模式：稍深的蓝绿色）
  Color get buttonPositiveBgColor => isDarkMode
      ? const Color(0xFF2D4F5A) // 暗黑模式：深蓝绿色
      : const Color(0xFF9FC4C9); // 白色模式：稍深的蓝绿色

  /// P- 和 B- 按钮背景颜色（暗黑模式：深棕灰色，白色模式：稍深的棕灰色）
  Color get buttonNegativeBgColor => isDarkMode
      ? const Color(0xFF4F4A4A) // 暗黑模式：深棕灰色
      : const Color(0xFFC0BCBC); // 白色模式：稍深的棕灰色

  var totalValue /*统计区*/ = <String>[];
  var chartData /*图表数据*/ = <LineChartDataModel>[];

  // List<SalesData> chartData/*图表数据*/ = List.generate(70, (index) =>SalesData(index.toString(),Random().nextInt(1).toDouble() )).toList().obs;
  var table1List = <Table1Model>[];

  var table2List = <Table2Model>[];
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
  var description = [
    {"本金", "总局数", "回合局数", "流水"},
    {"输赢后的金额", "总净胜", "回合净胜", "均利"},
    {"本金使用", "总净率", "回合胜率", "连胜负"},
    {"", "总净胜", "回合净胜", "庄/闲/差"},
    {"", "总输赢", "回合输赢", "期望值"},
    {"", "总平均赢", "回合平均赢", "总体：打庄时最小需要的值"},
    {"预测下一次的总体平均赢", "总体胜率回归时‘还需’", "回合胜率回归时‘还需’", "回合：打庄时最小需要的值"},
    {"下注的次数/随机次数", "显示随机庄闲", "....", "赔率"},
    // {"下注的次数/随机次数", "显示随机庄闲", "减10%/减30%/减50%", "赔率"},
  ];

  var isRefreshing = false;
  var isBigRoad = false;

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
  JiShuQiState() {
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
