import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'baccarat_simulation_state.dart';

/// 百家乐模拟控制器
/// 负责游戏逻辑、动画控制和状态管理
class BaccaratSimulationController extends GetxController with GetSingleTickerProviderStateMixin {
  // ========== 状态管理 ==========
  /// 游戏状态管理实例
  final BaccaratSimulationState state = BaccaratSimulationState();

  // ========== 动画控制 ==========
  /// 动画控制器，用于控制开奖动画
  late AnimationController animationController;

  /// 缩放动画，用于开奖结果的缩放效果
  late Animation<double> scaleAnimation;

  // ========== 滚动控制 ==========
  /// 大路图滚动控制器
  late ScrollController scrollController;

  // ========== 工具类 ==========
  /// 随机数生成器，用于生成随机卡片
  final Random _random = Random();

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _initializeBigRoad();
    _initializeScrollController();
  }

  @override
  void onClose() {
    animationController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 初始化动画控制器
  /// 设置开奖动画的持续时间和缩放效果
  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  /// 初始化大路图
  /// 调用State的初始化方法
  void _initializeBigRoad() {
    state.initializeBigRoad();
  }

  /// 初始化滚动控制器
  void _initializeScrollController() {
    scrollController = ScrollController();
  }

  /// 自动滚动到当前绘制位置
  void scrollToCurrentPosition(int currentCol) {
    // 使用 addPostFrameCallback 保证在当前帧绘制完成后再执行滚动，避免滚动区域未布局完成导致异常
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // 计算当前列右边界的位置
        double currentColRightEdge = (currentCol + 1) * BaccaratSimulationState.cellWidth;

        // 获取当前可见区域的右边界
        double currentScrollOffset = scrollController.position.pixels;
        double visibleRightEdge = currentScrollOffset + scrollController.position.viewportDimension;

        // 只有当当前列的右边界超出可见区域右边界时才滚动
        if (currentColRightEdge > visibleRightEdge) {
          // 计算需要滚动的距离，让当前列刚好可见
          double scrollDistance = currentColRightEdge - visibleRightEdge + BaccaratSimulationState.cellWidth;
          double newOffset = currentScrollOffset + scrollDistance;

          // 确保不超过最大滚动范围
          double maxOffset = scrollController.position.maxScrollExtent;
          if (newOffset > maxOffset) {
            newOffset = maxOffset;
          }

          scrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  /// 生成随机卡片
  /// 返回包含花色、点数、百家乐值和显示文本的卡片数据
  ///
  /// 百家乐点数规则：
  /// - A = 1点
  /// - 2-9 = 对应点数
  /// - 10, J, Q, K = 0点
  /// - 总点数 = 所有卡片点数之和 % 10
  Map<String, dynamic> _generateCard() {
    final suits = ['♠', '♥', '♦', '♣'];
    final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    final suit = suits[_random.nextInt(suits.length)];
    final rank = ranks[_random.nextInt(ranks.length)];

    // 计算百家乐点数
    int value;
    if (rank == 'A') {
      value = 1;
    } else if (['J', 'Q', 'K'].contains(rank)) {
      value = 0;
    } else {
      value = int.parse(rank);
    }

    return {
      'suit': suit, // 花色（♠♥♦♣）
      'rank': rank, // 点数（A,2-10,J,Q,K）
      'value': value, // 百家乐点数（0-9）
      'display': '$rank$suit', // 显示文本（如：A♠）
    };
  }

  /// 计算手牌总点数（百家乐规则）
  /// 百家乐点数计算：所有卡片点数之和取模10
  /// [cards] 手牌列表
  /// 返回0-9的点数
  int _calculateBaccaratTotal(List<Map<String, dynamic>> cards) {
    int total = 0;
    for (var card in cards) {
      total += card['value'] as int;
    }
    return total % 10;
  }

  /// 百家乐发牌规则
  /// 实现标准百家乐发牌和第三张牌规则
  ///
  /// 发牌顺序：
  /// 1. 闲家第一张，庄家第一张
  /// 2. 闲家第二张，庄家第二张
  /// 3. 根据第三张牌规则决定是否发第三张牌
  ///
  /// 返回：[闲家结果, 庄家结果]
  List<Map<String, dynamic>> _dealBaccaratCards() {
    List<Map<String, dynamic>> playerCards = [];
    List<Map<String, dynamic>> bankerCards = [];

    // 初始发牌：每人两张
    playerCards.add(_generateCard());
    bankerCards.add(_generateCard());
    playerCards.add(_generateCard());
    bankerCards.add(_generateCard());

    int playerTotal = _calculateBaccaratTotal(playerCards);
    int bankerTotal = _calculateBaccaratTotal(bankerCards);

    // 第三张牌规则
    bool playerGetsThird = playerTotal <= 5;
    bool bankerGetsThird = false;

    if (playerGetsThird) {
      playerCards.add(_generateCard());
      playerTotal = _calculateBaccaratTotal(playerCards);

      // 庄家第三张牌规则
      if (bankerTotal <= 2) {
        bankerGetsThird = true;
      } else if (bankerTotal == 3 && playerCards[2]['value'] != 8) {
        bankerGetsThird = true;
      } else if (bankerTotal == 4 && [2, 3, 4, 5, 6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      } else if (bankerTotal == 5 && [4, 5, 6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      } else if (bankerTotal == 6 && [6, 7].contains(playerCards[2]['value'])) {
        bankerGetsThird = true;
      }

      if (bankerGetsThird) {
        bankerCards.add(_generateCard());
        bankerTotal = _calculateBaccaratTotal(bankerCards);
      }
    } else if (bankerTotal <= 5) {
      bankerCards.add(_generateCard());
      bankerTotal = _calculateBaccaratTotal(bankerCards);
    }

    return [
      {'type': 'player', 'cards': playerCards, 'total': playerTotal},
      {'type': 'banker', 'cards': bankerCards, 'total': bankerTotal},
    ];
  }

  /// 开始模拟
  /// 执行一次完整的百家乐开奖模拟
  /// 包括：发牌、计算点数、判断胜负、更新大路图
  Future<void> startSimulation() async {
    if (state.isAnimating) return;

    // 开始动画状态
    startAnimation();
    update(); // 触发UI更新
    animationController.forward();

    // 模拟发牌过程
    await Future.delayed(const Duration(milliseconds: 500));

    final results = _dealBaccaratCards();
    final playerResult = results[0];
    final bankerResult = results[1];

    // 更新结果
    final playerCards = playerResult['cards'].map((card) => card['display']).join(' ');
    final bankerCards = bankerResult['cards'].map((card) => card['display']).join(' ');
    final playerTotal = playerResult['total'];
    final bankerTotal = bankerResult['total'];

    String winner;
    String currentResult;

    if (playerTotal > bankerTotal) {
      winner = '闲家';
      currentResult = '闲家胜 ($playerTotal vs $bankerTotal)';
    } else if (bankerTotal > playerTotal) {
      winner = '庄家';
      currentResult = '庄家胜 ($bankerTotal vs $playerTotal)';
    } else {
      winner = '和局';
      currentResult = '和局 ($playerTotal vs $bankerTotal)';
    }

    // 更新状态
    updateGameResult(
      playerCards: playerCards,
      bankerCards: bankerCards,
      playerTotal: playerTotal,
      bankerTotal: bankerTotal,
      winner: winner,
      currentResult: currentResult,
    );

    // 添加到历史记录
    final gameRecord = {
      'playerCards': playerCards,
      'bankerCards': bankerCards,
      'playerTotal': playerTotal,
      'bankerTotal': bankerTotal,
      'winner': winner,
      'timestamp': DateTime.now(),
    };

    addGameRecord(gameRecord);

    // 更新大路
    debugPrint('🎰 Controller: 准备更新大路，winner: $winner');
    updateBigRoad(winner);
    update(); // 触发GetBuilder更新

    // 自动滚动到当前位置
    scrollToCurrentPosition(state.currentCol);

    await Future.delayed(const Duration(milliseconds: 1000));

    // 完成动画状态
    endAnimation();
    update(); // 触发UI更新
    animationController.reset();
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
    debugPrint('🐉️ 上局: ${state.lastWinner} 当前: $winner');

    // 和局不记录在大路中
    if (winner == '和局') {
      return;
    }

    /************如果是第一局，直接记录在第1行第1列 ********************************************** */
    if (state.lastWinner == '') {
      debugPrint('🐉️ 第一局，记录在 [${state.currentRow}][${state.currentCol}]');
      state.bigRoad[state.currentRow][state.currentCol] = winner;
      state.currentCol++;
    }

    /************ 如果与上一局不同，向右移动（新列）************************************************/
    else if (state.lastWinner != winner) {
      state.dragonStartCol = -1;
      state.dragonParallelRow = -1;
      state.currentRow = 0;
      state.bigRoad[state.currentRow][state.currentCol] = winner;
      debugPrint('🐉️ 与上一局不同，记录在 [${state.currentRow}][${state.currentCol}]');
      state.currentCol++;
    }

    /************ 如果与上一局相同，向下移动 *****************************************************/
    else {
      state.currentRow++;
      var ids = state.currentCol - 1; // 当前列的列

      // 如果下方有内容，或者已经超过6行，则需要往右平移（长龙处理）
      if ((state.currentRow < BaccaratSimulationState.bigRoadRows && state.bigRoad[state.currentRow][ids].isNotEmpty) ||
          state.currentRow > BaccaratSimulationState.bigRoadRows - 1) {
        // 长龙处理：向右平移
        state.dragonStartCol++;
        state.bigRoad[state.dragonParallelRow][state.dragonStartCol] = winner;
        debugPrint('🐉️（长龙处理）与上一局相同，记录在 [${state.dragonParallelRow}][${state.dragonStartCol}]');
      } else {
        // 没有超过6行，且下方没有内容，正常往下走
        state.bigRoad[state.currentRow][state.currentCol - 1] = winner;
        state.dragonParallelRow = state.currentRow; // 记录最后一次行
        state.dragonStartCol = state.currentCol - 1; // 记录最后一次列
        debugPrint('🐉️ 与上一局相同，记录在 [${state.currentRow}][${state.currentCol - 1}]');
      }
    }

    state.lastWinner = winner;
  }

  /// 重置所有状态
  /// 清空所有游戏数据，回到初始状态
  void reset() {
    state.isAnimating = false;
    state.currentResult = '';
    state.playerCards = '';
    state.bankerCards = '';
    state.playerTotal = 0;
    state.bankerTotal = 0;
    state.winner = '';
    state.showResultArea = true;
    state.gameHistory.clear();
    state.roadMap.clear();
    _initializeBigRoad();
  }

  /// 开始动画状态
  /// 设置动画标志为true，显示结果区域
  void startAnimation() {
    state.isAnimating = true;
    state.showResultArea = true;
  }

  /// 结束动画状态
  /// 设置动画标志为false，隐藏结果区域
  void endAnimation() {
    state.isAnimating = false;
    state.showResultArea = false;
  }

  /// 添加游戏记录
  /// 将新的游戏结果添加到历史记录中
  /// [record] 游戏记录，包含手牌、点数、获胜者等信息
  void addGameRecord(Map<String, dynamic> record) {
    state.gameHistory.insert(0, record);
    state.roadMap.insert(0, record['winner']);

    // 限制历史记录数量
    if (state.gameHistory.length > 20) {
      state.gameHistory = state.gameHistory.take(20).toList();
    }

    if (state.roadMap.length > 50) {
      state.roadMap = state.roadMap.take(50).toList();
    }
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
    state.playerCards = playerCards;
    state.bankerCards = bankerCards;
    state.playerTotal = playerTotal;
    state.bankerTotal = bankerTotal;
    state.winner = winner;
    state.currentResult = currentResult;
  }

  /// 清空历史记录
  /// 重置所有游戏数据，清空大路图和历史记录
  void clearHistory() {
    reset();
    update(); // 触发UI更新
    // 滚动到起始位置
    scrollToCurrentPosition(0);
  }
}
