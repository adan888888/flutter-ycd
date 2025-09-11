import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
            onPressed: controller.clearHistory,
            tooltip: '清空历史',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
        // 构建大路图内容
        Widget bigRoadContent = Column(
          children: controller.state.bigRoad
              .map(
                (row) => Row(
                  children: row
                      .map(
                        (cell) => Container(
                          width: BaccaratSimulationState.cellWidth,
                          height: BaccaratSimulationState.cellWidth,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: cell.isEmpty ? null : _buildBigRoadItem(cell),
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: controller.state.hasBigRoadData
              ? SingleChildScrollView(
                  controller: controller.scrollController,
                  scrollDirection: Axis.horizontal,
                  child: bigRoadContent,
                )
              : Center(child: bigRoadContent), // 没有数据时居中显示
        );
      },
    );
  }

  // 构建大路图项
  Widget _buildBigRoadItem(String winner) {
    Color color;
    String text;
    switch (winner) {
      case '闲家':
        color = Colors.blue;
        text = 'P';
        break;
      case '庄家':
        color = Colors.red;
        text = 'B';
        break;
      default:
        color = Colors.grey;
        text = '?';
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
              builder: (controller) {
                if (!controller.state.showResultArea) {
                  return const SizedBox.shrink();
                }
                return AnimatedBuilder(
                  animation: controller.animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: controller.scaleAnimation.value,
                      child: _buildResultDisplay(),
                    );
                  },
                );
              },
            ),
            GetBuilder<BaccaratSimulationController>(
              builder: (controller) {
                if (controller.state.playerCards.isEmpty) {
                  return const SizedBox.shrink();
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

  // 构建结果显示
  Widget _buildResultDisplay() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _getResultColor(controller.state.winner).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getResultColor(controller.state.winner),
              width: 2,
            ),
          ),
          child: Text(
            controller.state.currentResult.isEmpty ? '点击开始模拟' : controller.state.currentResult,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getResultColor(controller.state.winner),
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
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

  // 构建玩家卡片
  Widget _buildPlayerCards() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPlayerCard(
              '闲家',
              controller.state.playerCards,
              controller.state.playerTotal,
              Colors.blue,
            ),
            _buildPlayerCard(
              '庄家',
              controller.state.bankerCards,
              controller.state.bankerTotal,
              Colors.red,
            ),
          ],
        );
      },
    );
  }

  // 构建单个玩家卡片
  Widget _buildPlayerCard(
    String title,
    String cards,
    int total,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cards,
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            '点数: $total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 构建开始按钮
  Widget _buildStartButton() {
    return GetBuilder<BaccaratSimulationController>(
      builder: (controller) {
        return ElevatedButton.icon(
          onPressed: controller.state.isAnimating ? null : controller.startSimulation,
          icon: controller.state.isAnimating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.casino),
          label: Text(controller.state.isAnimating ? '模拟中...' : '开始模拟'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            minimumSize: const Size(200, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
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
