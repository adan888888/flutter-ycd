// ignore_for_file: constant_identifier_names
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:ycd/model/linechart_data_model.dart';
import 'package:ycd/my_db/jsq_operation_record_model.dart';
import 'package:ycd/my_db/jsq_bet_record_model.dart';

class JiShuQiState {
  static const String tempIndexCmdInit = 'init'; // 页面首次加载：恢复后端已保存的局部平衡锚点
  static const String tempIndexCmdKeep = 'keep'; // 数据变化后刷新统计：保留当前局部平衡锚点
  static const String tempIndexCmdCancel = '取消'; // 用户主动取消局部平衡
  static const String tempIndexCmdReset = '重启'; // 重启局部数据后清空局部平衡锚点

  var ratio = 50; //庄闲占比(50=50%庄 50%闲；70=70%庄 30%闲，)
  static const OFFSET8431 = 8431; //庄闲占比是 庄60% 闲40%
  static const double height = 16 / 3;
  int LockScreenTime = 5; //锁屏时间（分钟）
  var isLoading = false;
  var isInitialDataLoading = true;
  var isCanPress = true;
  var randomValue = ''; //随机的出来的庄闲
  var floatButtonScale = 1.0; // 浮动按钮缩放比例，用于点击动画
  var bettingMoney = '';
  var js1 = 0; //随机总数
  var js2 = 0;
  int currentTempIndex = 0; // 局部平衡锚点行 id（与列表眼睛一致）；持久化为服务端 operationRecord.tempIndex → JsqOperationRecordModel.tempIndex

  /// 列表各列固定宽度（ji_shu_qi_view 投注记录行；过长用 FittedBox 缩小字体）
  static const double seqColMaxWidth = 34; // 序号+眼睛，约 4 个数字
  static const double sflColWidth = 32; // 胜负路固定宽
  /// 下注列：约 5 个数字宽度；超出时用 FittedBox 缩小字体（同统计区）
  static const double betColWidth = 45;

  /// 投注记录表每一行高度（与 ji_shu_qi_view._buildItem Container.height 一致）
  static const double bettingTableRowHeight = 26;

  /// 列表滚到「眼睛」行时，行顶相对可视区顶部的留白（ensureVisible alignment 换算用）
  static const double bettingTableScrollTopInset = 5;

  /// 右下角「回到眼睛」悬浮钮的 bottom（与 ji_shu_qi_view Positioned 一致）
  static const double jumpToEyeFabBottom = 90;

  /// 投注列表是否滚在底部：底部显示向上箭头（去眼睛），否则向下箭头（回底部）
  var isBettingListAtBottom = true;

  /// 投注记录为空时的缺省图（含「暂无投注记录」文案）
  static const String emptyBettingListAsset = 'assets/images/empty_betting_records.png';

  /// 统计区固定高度（吸顶 SliverPersistentHeader）
  static const double statsAreaHeight = 145;

  // 暗黑主题标志
  var isDarkMode = true;

  // 图表显示标志
  var isChartVisible = true;

  /// 投注表是否显示序号列；false 时眼睛与局部平衡点击在输赢列（默认隐藏）
  var isSeqVisible = false;

  /// false=红输绿赢，true=红赢绿输（默认）
  var isRedWinGreenLose = true;

  // 白色主题颜色
  var lineColor = Colors.black87.withValues(alpha: 0.8);
  var listViewColor = Colors.grey.shade50; // 浅灰白色
  var bgColor = Colors.grey.shade50; // 浅灰白色
  var chartBgColor = Colors.grey.shade50; // 图表背景（浅灰白色）
  var textColor = Colors.black;

  // 暗黑主题颜色（深蓝色调风格）
  var darkLineColor = Colors.white.withValues(alpha: 0.6);
  var darkListViewColor = const Color(0xFF0e1621); // 列表区背景（炭灰）
  var darkBgColor = const Color(0xFF0e1621); // 统计区 / 页面主背景
  var darkChartBgColor = const Color(0xFF0e1621); // 图表区背景
  var darkTextColor = const Color(0xFFF5F5F5); // 暗黑模式下的主文字色

  // 根据主题获取颜色
  Color get currentLineColor => isDarkMode ? darkLineColor : lineColor;

  Color get currentListViewColor => isDarkMode ? darkListViewColor : listViewColor;

  Color get currentBgColor => isDarkMode ? darkBgColor : bgColor;

  Color get currentChartBgColor => isDarkMode ? darkChartBgColor : chartBgColor;

  Color get currentTextColor => isDarkMode ? darkTextColor : textColor;

  /// 投注列表「重启行」底部分隔线颜色
  Color get currentRestartRowBorderColor => isDarkMode ? Colors.amberAccent.shade100 : Colors.black;

  /// 统计区 / 投注列表共用的下拉刷新头部；底色与所在区域背景一致，文字/图标保证可读
  ClassicHeader pullRefreshHeader({required Color backgroundColor}) => ClassicHeader(
        clamping: false,
        infiniteOffset: null,
        triggerWhenReach: false,
        triggerWhenRelease: false,
        dragText: '下拉加载',
        armedText: '松开加载',
        readyText: '加载中...',
        processingText: '加载中...',
        processedText: '加载成功',
        noMoreText: '没有更多了',
        failedText: '加载失败',
        messageText: '更新时间 %T',
        showMessage: true,
        backgroundColor: backgroundColor,
        textStyle: TextStyle(
          color: isDarkMode ? darkTextColor.withValues(alpha: 0.9) : Colors.black87,
          fontSize: 14,
        ),
        messageStyle: TextStyle(
          color: isDarkMode ? darkTextColor.withValues(alpha: 0.55) : Colors.black54,
          fontSize: 12,
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.75) : Colors.black54,
          size: 22,
        ),
      );

  // 列表 / 按钮输赢文字色（暗色：橙≈红、青绿≈绿）
  Color get _redTone => isDarkMode ? Colors.orange : Colors.red;

  Color get _greenTone => isDarkMode ? const Color(0xFF69B6AD) : Colors.green;

  /// 列表「输」
  Color get negativeColor => isRedWinGreenLose ? _greenTone : _redTone;

  /// 列表「赢」
  Color get positiveColor => isRedWinGreenLose ? _redTone : _greenTone;

  /// P+ / B+ 按钮文字（与列表「赢」一致）
  Color get buttonWinTextColor => positiveColor;

  /// P- / B- 按钮文字（与列表「输」一致）
  Color get buttonLossTextColor => negativeColor;

  /// 根据值判断字体颜色
  Color getValueColor(dynamic value) {
    if (value is num) {
      return value < 0 ? negativeColor : positiveColor;
    }
    final text = value?.toString() ?? '';
    return text.startsWith('-') ? negativeColor : positiveColor;
  }

  /// 输赢列展示：小数不足两位时补足两位；已满两位或更多则保持原样
  String formatShuyingzhiColumn(dynamic raw) {
    if (raw == null) return '';
    if (raw is num) {
      final n = raw.toDouble();
      if (n == 0) return '0.00';
      final body = n.abs().toStringAsFixed(2);
      return n < 0 ? '-$body' : '+$body';
    }
    if (raw is! String) return raw.toString();
    final s = raw.trim();
    final negative = s.startsWith('-');
    final positive = s.startsWith('+');
    final numStr = (negative || positive) ? s.substring(1) : s;
    final n = double.tryParse(numStr);
    if (n == null) return s;

    final dot = numStr.indexOf('.');
    final decimalPlaces = dot < 0 ? 0 : numStr.length - dot - 1;
    if (decimalPlaces >= 2) return s;

    final body = n.abs().toStringAsFixed(2);
    if (negative) return '-$body';
    if (positive) return '+$body';
    return body;
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

  Color get deleteLastIconColor => isDarkMode ? darkTextColor.withValues(alpha: 0.7) : Colors.black45;

  var totalValue /*统计区*/ = <String>[];
  var chartData /*图表数据*/ = <LineChartDataModel>[];

  // List<SalesData> chartData/*图表数据*/ = List.generate(70, (index) =>SalesData(index.toString(),Random().nextInt(1).toDouble() )).toList().obs;
  var operationRecordList = <JsqOperationRecordModel>[];

  var betRecordList = <JsqBetRecordModel>[];
  var selectIndex = 7;

  List<String> get functionTypes => [
        '1.排列数据',
        '2.消除数据',
        '3.修改本金',
        '4.修改位置',
        '5.删除所有数据',
        '6.重置流水',
        '7.备份数据',
        '8.重启系统',
        '9.修改期望值',
        '10.修改赔率',
        '11.退出程序',
        isSeqVisible ? '12.隐藏序号' : '12.显示序号',
        isRedWinGreenLose ? '13.红输绿赢' : '13.红赢绿输',
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
