import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../my_widget/baccarat_big_road_widget.dart';
import 'baccarat_hand_panel.dart';
import 'baccarat_shuffle_overlay.dart';
import 'baccarat_simulation_controller.dart';
import 'baccarat_simulation_state.dart';

class BaccaratSimulationView extends GetView<BaccaratSimulationController> {
  const BaccaratSimulationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('百家乐开奖模拟'),
        backgroundColor: Colors.amber.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              if (controller.state.isShuffling || controller.state.isAnimating) return;
              controller.clearHistory();
            },
            tooltip: '清空历史',
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 路子图
                  _buildRoadMap(),
                  const SizedBox(height: 24),
                  // 开奖结果区域
                  _buildResultSection(),
                  const SizedBox(height: 24),
                  // 开始按钮
                  _buildStartButton(),
                  const SizedBox(height: 24),
                  // 历史记录
                  _buildHistorySection(),
                ],
              ),
            ),
          ),
          GetBuilder<BaccaratSimulationController>(
            builder: (controller) {
              if (!controller.state.isShuffling) {
                return const SizedBox.shrink();
              }
              return const BaccaratShuffleOverlay();
            },
          ),
        ],
      ),
    );
  }

  // 构建路子图
  Widget _buildRoadMap() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        if (!controller.state.hasBigRoadData) {
          return _buildEmptyRoadMap();
        }
        return _buildBigRoadMap();
      },
    );
  }

  // 构建空的路子图
  Widget _buildEmptyRoadMap() {
    return Center(
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '大路',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无数据',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建大路图
  Widget _buildBigRoadMap() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '大路',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem('闲家', Colors.blue),
                    const SizedBox(width: 12),
                    _buildLegendItem('庄家', Colors.red),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 大路网格
            _buildBigRoadGrid(),
          ],
        ),
      ),
    );
  }

  // 构建图例项
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // 构建大路网格
  Widget _buildBigRoadGrid() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return BaccaratBigRoadWidget(
          bigRoadData: controller.state.bigRoad,
          cellWidth: BaccaratSimulationState.cellWidth,
          cellHeight: BaccaratSimulationState.cellWidth,
          hasData: controller.state.hasBigRoadData,
          scrollController: controller.scrollController,
          borderColor: Colors.grey.shade300,
          backgroundColor: Colors.white,
          borderRadius: 8.0,
          showBorder: true,
        );
      },
    );
  }

  // 构建开奖结果区域
  Widget _buildResultSection() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '当前开奖结果',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
            GetBuilder<BaccaratSimulationController>(
              builder: (controller) => _buildShoeInfoPanel(controller),
            ),
            GetBuilder<BaccaratSimulationController>(
              builder: (controller) {
                final hasCards =
                    controller.state.playerCardsList.isNotEmpty || controller.state.bankerCardsList.isNotEmpty;
                if (!hasCards && !controller.state.isAnimating) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '点击开始模拟',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  );
                }
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildPlayerCards(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoeInfoPanel(BaccaratSimulationController controller) {
    final state = controller.state;
    if (state.isShuffling) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '8副牌牌靴 · 正在洗牌',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }
    if (state.awaitingCutCard) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '洗牌完成',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '牌靴剩余',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  '${state.shoeRemaining}/${BaccaratSimulationState.shoeTotalCards} 张',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '切牌位',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  state.shoeCutCardChosen ? '≤ ${state.shoeCutCardRemaining} 张' : '请点击随机',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: state.shoeCutCardChosen ? Colors.blue.shade800 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: controller.randomizeCutCard,
              icon: const Icon(Icons.content_cut, size: 18),
              label: const Text('随机切牌'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // 获取结果颜色
  Color _getResultColor(String winner) {
    switch (winner) {
      case '闲家':
        return Colors.blue;
      case '庄家':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPlayerCards() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BaccaratHandPanel(
              title: '闲家',
              cards: controller.state.playerCardsList,
              total: controller.state.playerTotal,
              color: Colors.blue,
              flash: controller.state.winnerFlashSide == 'player',
            ),
            BaccaratHandPanel(
              title: '庄家',
              cards: controller.state.bankerCardsList,
              total: controller.state.bankerTotal,
              color: Colors.red,
              flash: controller.state.winnerFlashSide == 'banker',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStartButton() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed:
                  (controller.state.isAnimating || controller.state.isShuffling || controller.state.awaitingCutCard)
                      ? null
                      : controller.startSimulation,
              icon: controller.state.isAnimating || controller.state.isShuffling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.casino),
              label: Text(
                controller.state.isShuffling
                    ? '洗牌中...'
                    : (controller.state.isAnimating ? '发牌中...' : (controller.state.awaitingCutCard ? '请先切牌' : '发牌')),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.state.isShuffling
                  ? '8副牌牌靴 · 正在洗牌'
                  : controller.state.awaitingCutCard
                      ? '8副牌牌靴 · 洗牌完成，请先随机切牌位'
                      : '8副牌牌靴 · 剩余 ${controller.state.shoeRemaining}/${BaccaratSimulationState.shoeTotalCards} 张'
                          ' · 切牌≤${controller.state.shoeCutCardRemaining}'
                          '${controller.state.shoeRemaining > 0 && controller.state.shoeRemaining <= controller.state.shoeCutCardRemaining ? '（本靴已发完）' : ''}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }

  // 构建历史记录区域
  Widget _buildHistorySection() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        if (controller.state.gameHistory.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '历史记录',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...controller.state.gameHistory.map((game) => _buildHistoryItem(game)),
          ],
        );
      },
    );
  }

  // 构建历史记录项
  Widget _buildHistoryItem(Map<String, dynamic> game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '闲家: ${game['playerCards']} (${game['playerTotal']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    '庄家: ${game['bankerCards']} (${game['bankerTotal']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getResultColor(game['winner']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                game['winner'],
                style: TextStyle(
                  color: _getResultColor(game['winner']),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
