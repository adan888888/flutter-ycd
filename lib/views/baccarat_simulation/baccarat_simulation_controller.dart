import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'baccarat_shoe.dart';
import 'baccarat_shuffle_overlay.dart';
import 'baccarat_simulation_state.dart';

class _DealStep {
  const _DealStep({
    required this.side,
    required this.card,
    this.isThirdCard = false,
  });

  final String side;
  final Map<String, dynamic> card;
  final bool isThirdCard;
}

class _BaccaratHandResult {
  const _BaccaratHandResult({
    required this.playerCards,
    required this.bankerCards,
    required this.playerTotal,
    required this.bankerTotal,
    required this.steps,
  });

  final List<Map<String, dynamic>> playerCards;
  final List<Map<String, dynamic>> bankerCards;
  final int playerTotal;
  final int bankerTotal;
  final List<_DealStep> steps;
}

/// 百家乐模拟控制器
/// 负责游戏逻辑、动画控制和状态管理
class BaccaratSimulationController extends GetxController {
  // ========== 状态管理 ==========
  /// 游戏状态管理实例
  final BaccaratSimulationState state = BaccaratSimulationState();

  // ========== 滚动控制 ==========
  /// 大路图滚动控制器
  late ScrollController scrollController;

  // ========== 工具类 ==========
  /// 8 副牌牌靴
  final BaccaratShoe _shoe = BaccaratShoe();

  @override
  void onInit() {
    super.onInit();
    _initializeBigRoad();
    _initializeScrollController();
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(playShuffleAnimation());
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
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

  void _syncShoeRemaining() {
    state.shoeRemaining = _shoe.remaining;
  }

  /// 播放 8 副牌洗牌动画（动画开始时立即洗牌）
  Future<void> playShuffleAnimation() async {
    if (state.isShuffling) return;

    state.isShuffling = true;
    state.isAnimating = true;
    _shoe.shuffle();
    _syncShoeRemaining();
    update();

    await Future.delayed(BaccaratShuffleOverlay.animationDuration);

    state.isShuffling = false;
    state.isAnimating = false;
    update();
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

  /// 百家乐发牌规则，返回完整手牌及按真实顺序的发牌步骤
  _BaccaratHandResult _prepareBaccaratHand() {
    final playerCards = <Map<String, dynamic>>[];
    final bankerCards = <Map<String, dynamic>>[];
    final steps = <_DealStep>[];

    void dealToPlayer({bool isThirdCard = false}) {
      final card = _shoe.draw();
      playerCards.add(card);
      steps.add(_DealStep(side: 'player', card: card, isThirdCard: isThirdCard));
    }

    void dealToBanker({bool isThirdCard = false}) {
      final card = _shoe.draw();
      bankerCards.add(card);
      steps.add(_DealStep(side: 'banker', card: card, isThirdCard: isThirdCard));
    }

    // 初始发牌：闲1 → 庄1 → 闲2 → 庄2
    dealToPlayer();
    dealToBanker();
    dealToPlayer();
    dealToBanker();

    var playerTotal = _calculateBaccaratTotal(playerCards);
    var bankerTotal = _calculateBaccaratTotal(bankerCards);

    // 天牌（例牌）：任一方前两张为 8 或 9，双方均不补牌
    if (playerTotal >= 8 || bankerTotal >= 8) {
      return _BaccaratHandResult(
        playerCards: playerCards,
        bankerCards: bankerCards,
        playerTotal: playerTotal,
        bankerTotal: bankerTotal,
        steps: steps,
      );
    }

    // 第三张牌规则
    final playerGetsThird = playerTotal <= 5;
    if (playerGetsThird) {
      dealToPlayer(isThirdCard: true);
      playerTotal = _calculateBaccaratTotal(playerCards);

      var bankerGetsThird = false;
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
        dealToBanker(isThirdCard: true);
        bankerTotal = _calculateBaccaratTotal(bankerCards);
      }
    } else if (bankerTotal <= 5) {
      dealToBanker(isThirdCard: true);
      bankerTotal = _calculateBaccaratTotal(bankerCards);
    }

    return _BaccaratHandResult(
      playerCards: playerCards,
      bankerCards: bankerCards,
      playerTotal: playerTotal,
      bankerTotal: bankerTotal,
      steps: steps,
    );
  }

  String _cardsToDisplay(List<Map<String, dynamic>> cards) {
    return cards.map((card) => card['display'] as String).join(' ');
  }

  void _clearDealingBoard() {
    state.playerCardsList = [];
    state.bankerCardsList = [];
    state.playerCards = '';
    state.bankerCards = '';
    state.playerTotal = 0;
    state.bankerTotal = 0;
    state.winner = '';
    state.currentResult = '';
    state.winnerFlashSide = '';
  }

  Future<void> _playWinnerFlash(String winner) async {
    if (winner == '闲家') {
      state.winnerFlashSide = 'player';
    } else if (winner == '庄家') {
      state.winnerFlashSide = 'banker';
    } else {
      return;
    }
    update();
    await Future.delayed(const Duration(milliseconds: 900));
    state.winnerFlashSide = '';
    update();
  }

  Future<void> _revealDealSteps(List<_DealStep> steps) async {
    for (final step in steps) {
      if (step.isThirdCard) {
        await Future.delayed(const Duration(seconds: 2));
      }
      if (step.side == 'player') {
        state.playerCardsList = [...state.playerCardsList, step.card];
        state.playerTotal = _calculateBaccaratTotal(state.playerCardsList);
      } else {
        state.bankerCardsList = [...state.bankerCardsList, step.card];
        state.bankerTotal = _calculateBaccaratTotal(state.bankerCardsList);
      }
      update();
      await Future.delayed(const Duration(milliseconds: 420));
    }
  }

  /// 开始模拟
  /// 按百家乐顺序逐张发牌并播放动画
  Future<void> startSimulation() async {
    if (state.isAnimating) return;

    startAnimation();
    _clearDealingBoard();
    if (_shoe.needsReshuffleBeforeHand()) {
      await playShuffleAnimation();
      startAnimation();
      _clearDealingBoard();
    }
    _syncShoeRemaining();
    update();

    final hand = _prepareBaccaratHand();
    await _revealDealSteps(hand.steps);
    _syncShoeRemaining();

    final playerCards = _cardsToDisplay(hand.playerCards);
    final bankerCards = _cardsToDisplay(hand.bankerCards);
    final playerTotal = hand.playerTotal;
    final bankerTotal = hand.bankerTotal;

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

    updateGameResult(
      playerCards: playerCards,
      bankerCards: bankerCards,
      playerTotal: playerTotal,
      bankerTotal: bankerTotal,
      winner: winner,
      currentResult: currentResult,
    );

    await _playWinnerFlash(winner);

    addGameRecord({
      'playerCards': playerCards,
      'bankerCards': bankerCards,
      'playerTotal': playerTotal,
      'bankerTotal': bankerTotal,
      'winner': winner,
      'timestamp': DateTime.now(),
    });

    updateBigRoad(winner);
    update();
    scrollToCurrentPosition(state.currentCol);

    await Future.delayed(const Duration(milliseconds: 300));
    endAnimation();
    update();
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
    state.playerCardsList = [];
    state.bankerCardsList = [];
    state.playerTotal = 0;
    state.bankerTotal = 0;
    state.winner = '';
    state.winnerFlashSide = '';
    state.showResultArea = true;
    state.gameHistory.clear();
    state.roadMap.clear();
    state.shoeRemaining = 0;
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
  Future<void> clearHistory() async {
    if (state.isShuffling || state.isAnimating) return;
    reset();
    update();
    await playShuffleAnimation();
    scrollToCurrentPosition(0);
  }
}
