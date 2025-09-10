import 'package:flutter/material.dart';

/// 百家乐模拟状态管理
class BaccaratSimulationState {
  // ***********== 常量定义 ***********==
  /// 大路图行数
  static const int bigRoadRows = 6;

  /// 大路图列数
  static const int bigRoadCols = 120;

  /// 每个格子的宽度（像素）
  static const double cellWidth = 20.0;

  // ***********== 游戏状态 ***********==
  /// 是否正在播放动画
  bool isAnimating = false;

  /// 当前开奖结果文本（如：闲家胜 (8 vs 6)）
  String currentResult = '';

  /// 闲家手牌显示文本（如：♠A ♥K）
  String playerCards = '';

  /// 庄家手牌显示文本（如：♦2 ♣5）
  String bankerCards = '';

  /// 闲家总点数（0-9）
  int playerTotal = 0;

  /// 庄家总点数（0-9）
  int bankerTotal = 0;

  /// 本局获胜者（闲家/庄家/和局）
  String winner = '';

  /// 是否显示开奖结果区域
  bool showResultArea = true;

  // ***********== 历史记录和路子图 ***********==
  /// 游戏历史记录列表（最多保存20局）
  List<Map<String, dynamic>> gameHistory = [];

  /// 简单的路子图记录（用于其他路子图显示）
  List<String> roadMap = [];

  /// 大路图数据（6行30列的二维数组）
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
  int recordRightCol = 0; //记录横向时候的列
  /// 构造函数
  /// 初始化大路图数据
  BaccaratSimulationState() {
    initializeBigRoad();
  }

  /// 重置所有状态
  /// 清空所有游戏数据，回到初始状态
  void reset() {
    isAnimating = false;
    currentResult = '';
    playerCards = '';
    bankerCards = '';
    playerTotal = 0;
    bankerTotal = 0;
    winner = '';
    showResultArea = true;
    gameHistory.clear();
    roadMap.clear();
    initializeBigRoad();
  }

  /// 开始动画状态
  /// 设置动画标志为true，显示结果区域
  void startAnimation() {
    isAnimating = true;
    showResultArea = true;
  }

  /// 结束动画状态
  /// 设置动画标志为false，隐藏结果区域
  void endAnimation() {
    isAnimating = false;
    showResultArea = false;
  }

  /// 添加游戏记录
  /// 将新的游戏结果添加到历史记录中
  /// [record] 游戏记录，包含手牌、点数、获胜者等信息
  void addGameRecord(Map<String, dynamic> record) {
    gameHistory.insert(0, record);
    roadMap.insert(0, record['winner']);

    // 限制历史记录数量
    if (gameHistory.length > 20) {
      gameHistory = gameHistory.take(20).toList();
    }

    if (roadMap.length > 50) {
      roadMap = roadMap.take(50).toList();
    }
  }

  /// 更新大路图
  /// 根据百家乐大路规则更新大路图数据
  /// [winner] 本局获胜者（闲家/庄家/和局）
  ///
  /// 大路规则：
  /// - 和局不记录在大路中
  /// - 第一局记录在[0][0]位置
  /// - 与上局不同：向右移动（新列）
  /// - 与上局相同：向下移动（同列）
  /// - 长龙规则（标准）：同列向下，若到底或下方被占，则锁定当前行改为向右平移

  void updateBigRoad(String winner) {
    debugPrint('🛣️ updateBigRoad called with winner: $winner');
    debugPrint('🛣️ lastWinner: $lastWinner');
    debugPrint('🛣️ currentRow: $currentRow, currentCol: $currentCol');

    // 和局不记录在大路中
    if (winner == '和局') {
      debugPrint('🛣️ 和局，不记录在大路中');
      return;
    }

    /************如果是第一局，直接记录在第1行第1列 *********** */
    if (lastWinner == '') {
      debugPrint('🐉️ 第一局，记录在 [$currentRow][$currentCol]');
      bigRoad[currentRow][currentCol] = winner;
      currentCol++;
    }
    /************ 如果与上一局不同，向右移动（新列）************/
    else if (lastWinner != winner) {
      debugPrint('🐉️ 与上一局不同，记录在 [$currentRow][$currentCol]');
      bigRoad[currentRow][currentCol] = winner;
      currentCol++;
    }
    /************ 如果与上一局相同，向下移动*********** */
    else {
      debugPrint('🐉️ 相同结果，向下移动');

      // 边界检查
      if (currentCol <= 0) {
        return;
      }

      // 当前运行中的列（上一手所在列）
      int colIdx = currentCol - 1;

      bigRoad[dragonParallelRow][currentCol] = winner;
    }

    lastWinner = winner;
  }

  /// 初始化大路图
  /// 创建6行120列的空大路图，重置所有位置状态
  void initializeBigRoad() {
    bigRoad = List.generate(
        bigRoadRows, (index) => List.generate(bigRoadCols, (index) => ''));
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
    debugPrint('🛣️ hasBigRoadData: $hasData');
    debugPrint('🛣️ bigRoad content: $bigRoad');
    return hasData;
  }

  /// 更新游戏结果
  /// 更新当前游戏的所有结果数据
  /// [playerCards] 闲家手牌显示文本
  /// [bankerCards] 庄家手牌显示文本
  /// [playerTotal] 闲家总点数
  /// [bankerTotal] 庄家总点数
  /// [winner] 获胜者
  /// [currentResult] 结果描述文本
  void updateGameResult({
    required String playerCards,
    required String bankerCards,
    required int playerTotal,
    required int bankerTotal,
    required String winner,
    required String currentResult,
  }) {
    this.playerCards = playerCards;
    this.bankerCards = bankerCards;
    this.playerTotal = playerTotal;
    this.bankerTotal = bankerTotal;
    this.winner = winner;
    this.currentResult = currentResult;
  }
}
