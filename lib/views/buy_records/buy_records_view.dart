import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'buy_records_controller.dart';

class BuyRecordsView extends StatelessWidget {
  const BuyRecordsView({super.key});

  // 使用 getter 替代 late final（兼容 const 构造函数）
  double get _defaultPadding => 16.0;

  double get _smallPadding => 8.0;

  double get _cardPadding => 10.0;

  double get _currencyCardHeight => 80.0;

  double get _iconSize => 64.0;

  double get _currencyIconSize => 24.0;

  // 样式 getter
  TextStyle get _titleStyle => const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

  TextStyle get _recordNumberStyle => const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue);

  TextStyle get _labelStyle => const TextStyle(fontSize: 11, color: Colors.grey);

  TextStyle get _valueStyle => const TextStyle(fontSize: 12, fontWeight: FontWeight.w800);

  TextStyle get _smallLabelStyle => const TextStyle(fontSize: 10, color: Colors.grey);

  TextStyle get _smallValueStyle => const TextStyle(fontSize: 10, fontWeight: FontWeight.w800);

  /// 「统计信息」区块底色（与外层 Card 区分）
  Color get _statsPanelBackground => const Color(0xFFE8EEF4);

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
      return _buildLoadingState();
    }

    if (controller.state.errorMessage != null) {
      return _buildErrorState(controller);
    }

    return _buildContent(controller);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: _defaultPadding),
          const Text('正在加载买入记录...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuyRecordsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: _iconSize, color: Colors.red[300]),
          SizedBox(height: _defaultPadding),
          Text(
            controller.state.errorMessage!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _defaultPadding),
          ElevatedButton(
            onPressed: () => controller.refreshAllData(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuyRecordsController controller) {
    return RefreshIndicator(
      onRefresh: controller.refreshAllData,
      child: ListView(
        padding: EdgeInsets.all(_defaultPadding),
        children: [
          _buildCurrencySelector(controller),
          SizedBox(height: _defaultPadding),
          _buildRecordsList(controller),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuyRecordsController controller) {
    if (controller.state.buyRecords.isEmpty) {
      return _buildEmptyState();
    }

    // state 已为 [最新…最旧]，从上到下直接按序展示
    return Column(
      children: List.generate(controller.state.buyRecords.length, (index) {
        final record = controller.state.buyRecords[index];
        return _buildRecordCard(controller, record, index);
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: _iconSize, color: Colors.grey),
          SizedBox(height: _defaultPadding),
          const Text('暂无买入记录', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuyRecordsController controller, Map<String, dynamic> record, int index) {
    // 最新一笔在列表最上方（index == 0），统计信息只在这一行展示
    final isLastRecord = index == 0;
    final hasCurrentPrice = controller.state.currentPrice != null;

    return Card(
      child: Padding(
        padding: EdgeInsets.only(
          left: _cardPadding,
          right: _cardPadding,
          top: 0,
          bottom: _cardPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 只有最后一条记录才显示收益统计
            if (hasCurrentPrice && isLastRecord) ...[
              _buildCurrentProfitStats(controller, index),
              SizedBox(height: _defaultPadding),
            ],

            _buildRecordHeader(controller, index),
            _buildCompactRecordDetails(controller, record),
            _buildCumulativeStats(controller, index),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHeader(BuyRecordsController controller, int index) {
    final n = controller.state.buyRecords.length;
    // index 0 = 时间上最后一笔（最新），笔号从最早为第1笔计起
    final purchaseNo = n - index;
    final qty = controller.calculateCumulativeStatsForRow(index)['totalQuantity'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('第$purchaseNo笔', style: _recordNumberStyle),
        SizedBox(width: _defaultPadding),
        _buildStatItemX(
          '累计成交数量 ',
          qty == null ? '—' : (qty as num).toStringAsFixed(8),
          Colors.grey,
        ),
      ],
    );
  }

  Widget _buildCompactRecordDetails(BuyRecordsController controller, Map<String, dynamic> record) {
    return Row(
      children: [
        Text('成交价格', style: _labelStyle),
        Text(
          controller.formatTransactionPrice(record['buy_price']),
          style: _valueStyle,
        ),
        SizedBox(width: _smallPadding),
        Text('成交金额', style: _labelStyle),
        Text(
          record['buy_amount']?.toString().isEmpty == true ? '未知' : "\$${record['buy_amount']}",
          style: _valueStyle,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: _labelStyle),
        Text(value, style: _valueStyle.copyWith(color: color)),
        SizedBox(width: _smallPadding),
      ],
    );
  }

  Widget _buildStatItemX(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: _smallLabelStyle),
        Text(value, style: _smallValueStyle.copyWith(color: color)),
        SizedBox(width: _smallPadding),
      ],
    );
  }

  Widget _buildCumulativeStats(BuyRecordsController controller, int reversedIndex) {
    final stats = controller.calculateCumulativeStatsForRow(reversedIndex);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Row(
          children: [
            _buildStatItem('成本价', controller.formatCostPrice(stats['averagePrice']), Colors.black),
            _buildStatItem('累计金额', controller.formatPriceInteger(stats['totalCost']), Colors.black),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentProfitStats(BuyRecordsController controller, int index) {
    final profitStats = controller.calculateCurrentProfitStatsForRow(index);
    if (profitStats.isEmpty) return const SizedBox.shrink();

    final profit = profitStats['profit'] as double;
    final isProfit = profit >= 0;
    final profitColor = isProfit ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: _statsPanelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('统计信息', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
          const SizedBox(height: 6),
          Column(
            children: [
              _buildStatItem(
                '收益率    ',
                '${profitStats['profitPercentage'].toStringAsFixed(2)}%',
                profitColor,
              ),
              _buildStatItem(
                '浮动盈亏',
                controller.formatPriceFourDecimals(profit),
                profitColor,
              ),
            ],
          ),
          _buildStatItem('当前价格', controller.formatCurrentPrice(controller.state.currentPrice!), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(BuyRecordsController controller) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(_defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择币种',
              style: _titleStyle.copyWith(color: Colors.grey[700]),
            ),
            SizedBox(height: _defaultPadding),
            Row(
              children: [
                _buildCurrencyCard(controller, 'btc', 'BTC', Colors.orange),
                const SizedBox(width: 12),
                _buildCurrencyCard(controller, 'eth', 'ETH', Colors.blue),
                const SizedBox(width: 12),
                _buildCurrencyCard(controller, 'ada', 'ADA', Colors.green),
                const SizedBox(width: 12),
                _buildCurrencyCard(controller, 'trx', 'TRX', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(BuyRecordsController controller, String currency, String label, Color color) {
    final isSelected = controller.state.currentCurrency == currency;

    return Expanded(
      child: InkWell(
        onTap: () => controller.switchCurrency(currency),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: _currencyCardHeight,
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
                size: _currencyIconSize,
                color: isSelected ? color : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
