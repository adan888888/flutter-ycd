import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'buy_records_controller.dart';

class BuyRecordsView extends StatelessWidget {
  const BuyRecordsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BuyRecordsController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('买入记录'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.refreshAllData,
                tooltip: '刷新数据',
              ),
            ],
          ),
          body: _buildBody(controller),
        );
      },
    );
  }

  Widget _buildBody(BuyRecordsController controller) {
    if (controller.state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载买入记录...'),
          ],
        ),
      );
    }

    if (controller.state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              controller.state.errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => controller.refreshAllData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 币种切换区域
          _buildCurrencySelector(controller),
          const SizedBox(height: 16),
          // 买入记录列表区域
          if (controller.state.buyRecords.isEmpty)
            // 没有记录时显示提示
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无买入记录', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          else
            // 有记录时显示列表
            ...List.generate(controller.state.buyRecords.length, (index) {
              final recordIndex = controller.state.buyRecords.length - 1 - index; // 倒序索引
              final record = controller.state.buyRecords[recordIndex];
              return _buildRecordCard(controller, record, recordIndex);
            }),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuyRecordsController controller, Map<String, dynamic> record, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '第${index + 1}笔#',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Row(
              children: [
                Expanded(child: _buildCompactRecordDetails(controller, record)),
              ],
            ),
            const Divider(height: 8),
            // 累计投资统计 (前N笔)
            _buildCumulativeStats(controller, index + 1),
            // 只有最后一条记录才显示与当前价格的比较，并且只在有内容时才显示分隔线
            if (controller.state.currentPrice != null && index == controller.state.buyRecords.length - 1) ...[
              const Divider(height: 6),
              _buildCurrentProfitStats(controller, index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRecordDetails(BuyRecordsController controller, Map<String, dynamic> record) {
    return Row(
      children: [
        const Text('买入价格: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          controller.formatPriceWithDecimals(record['buy_price']),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 20),
        const Text('数量: ', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          record['buy_amount']?.toString() ?? '未知',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Text('$label ', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8), // 添加右侧间距
      ],
    );
  }

  Widget _buildCumulativeStats(BuyRecordsController controller, int recordCount) {
    final stats = controller.calculateCumulativeStats(recordCount);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Row(
          children: [
            _buildStatItem('总成本', controller.formatPriceInteger(stats['totalCost']), Colors.black),
            _buildStatItem('均价', controller.formatPriceTwoDecimals(stats['averagePrice']), Colors.black),
            Expanded(
              child: _buildStatItem('总数量', stats['totalQuantity'].toStringAsFixed(8), Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentProfitStats(BuyRecordsController controller, int index) {
    final profitStats = controller.calculateCurrentProfitStats(index);
    if (profitStats.isEmpty) return const SizedBox.shrink();

    final profit = profitStats['profit'] as double;
    final isProfit = profit >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('统计信息', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 2),
        Column(
          children: [
            _buildStatItem(
              '收益率    ',
              '${profitStats['profitPercentage'].toStringAsFixed(2)}%',
              isProfit ? Colors.green : Colors.red,
            ),
            _buildStatItem(
              '累计收益',
              controller.formatPriceFourDecimals(profit),
              isProfit ? Colors.green : Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 3),
        _buildStatItem('当前价格', controller.formatPrice(controller.state.currentPrice!), Colors.blue),
      ],
    );
  }

  // 构建币种选择器
  Widget _buildCurrencySelector(BuyRecordsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择币种',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCurrencyCard(controller, 'btc', 'BTC', Colors.orange),
                const SizedBox(width: 12),
                _buildCurrencyCard(controller, 'eth', 'ETH', Colors.blue),
                const SizedBox(width: 12),
                _buildCurrencyCard(controller, 'ada', 'ADA', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建币种选择卡片
  Widget _buildCurrencyCard(BuyRecordsController controller, String currency, String label, Color color) {
    final isSelected = controller.state.currentCurrency == currency;
    return Expanded(
      child: InkWell(
        onTap: () => controller.switchCurrency(currency),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '($label)',
                style: TextStyle(
                  color: isSelected ? color : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.attach_money,
                size: 24,
                color: isSelected ? color : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
