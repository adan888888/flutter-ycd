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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildCurrencySelector(controller),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: _buildStickyStatsSliver(controller),
          ),
          _buildRecordsSliver(controller),
        ],
      ),
    );
  }

  Widget _buildRecordsSliver(BuyRecordsController controller) {
    if (controller.state.buyRecords.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: _defaultPadding),
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      sliver: SliverList.builder(
        itemCount: controller.state.buyRecords.length,
        itemBuilder: (context, index) {
          final record = controller.state.buyRecords[index];
          return _buildRecordCard(controller, record, index);
        },
      ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            _buildRecordHeader(controller, index),
            _buildCompactRecordDetails(controller, record),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatsPanel(BuyRecordsController controller) {
    if (controller.state.buyRecords.isEmpty || controller.state.currentPrice == null) {
      return const SizedBox.shrink();
    }

    // 列表已按 [最新...最旧] 排序，统计信息展示顶部最新一笔对应的累计结果。
    return _buildCurrentProfitStats(controller, 0);
  }

  Widget _buildStickyStatsSliver(BuyRecordsController controller) {
    final statsPanel = _buildTopStatsPanel(controller);
    if (statsPanel is SizedBox) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StatsHeaderDelegate(
        extent: 100,
        child: ColoredBox(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: statsPanel,
          ),
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
        Text('成交价', style: _labelStyle),
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

  Widget _buildCurrentProfitStats(BuyRecordsController controller, int index) {
    final profitStats = controller.calculateCurrentProfitStatsForRow(index);
    if (profitStats.isEmpty) return const SizedBox.shrink();

    final cumulativeStats = controller.calculateCumulativeStatsForRow(index);
    final profit = profitStats['profit'] as double;
    final isProfit = profit >= 0;
    final profitLabel = isProfit ? '浮盈' : '浮亏';
    final profitColor = isProfit ? Colors.green : Colors.red;
    final maDeviation = controller.ma200DailyDeviationPercent;
    final maColor = maDeviation == null ? Colors.grey : (maDeviation >= 0 ? Colors.green : Colors.red);
    final maText = maDeviation == null ? '—' : '${maDeviation >= 0 ? '+' : ''}${maDeviation.toStringAsFixed(2)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: _statsPanelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '统计信息',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('当前价格', style: _labelStyle),
                    Text(
                      controller.formatCurrentPrice(controller.state.currentPrice!),
                      style: _valueStyle.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem(
                      '累计金额',
                      cumulativeStats.isEmpty ? '—' : controller.formatPriceInteger(cumulativeStats['totalCost']),
                      Colors.black,
                    ),
                    _buildStatItem(
                      '收益      ',
                      '${profitStats['profitPercentage'].toStringAsFixed(2)}%',
                      profitColor,
                    ),
                    Row(
                      children: [
                        _buildStatItem(
                          '200MA',
                          controller.state.ma200Daily == null
                              ? '—'
                              : controller.formatMaPrice(controller.state.ma200Daily!),
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem(
                      '成本',
                      cumulativeStats.isEmpty ? '—' : controller.formatCostPrice(cumulativeStats['averagePrice']),
                      Colors.black,
                    ),
                    _buildStatItem(
                      profitLabel,
                      controller.formatPriceFourDecimals(profit),
                      profitColor,
                    ),
                    _buildStatItem(
                      '偏离',
                      maText,
                      maColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(BuyRecordsController controller) {
    return Card(
      margin: EdgeInsets.zero,
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

class _StatsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _StatsHeaderDelegate({
    required this.extent,
    required this.child,
  });

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StatsHeaderDelegate oldDelegate) {
    return extent != oldDelegate.extent || child != oldDelegate.child;
  }
}
