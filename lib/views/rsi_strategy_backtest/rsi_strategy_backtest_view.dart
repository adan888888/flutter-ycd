import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'rsi_strategy_backtest_controller.dart';

class RSIStrategyBacktestView extends GetView<RSIStrategyBacktestController> {
  const RSIStrategyBacktestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('${controller.getCoinName(controller.selectedCoin.value)} 两周定投回测 - 最近1年')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 币种选择
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择币种', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.coinList.length,
                          itemBuilder: (context, index) {
                            final coin = controller.coinList[index];
                            return Obx(() {
                              final isSelected = controller.selectedCoin.value == coin['symbol'];
                              return GestureDetector(
                                onTap: () => controller.selectCoin(coin['symbol']),
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? coin['color'].withValues(alpha: 0.2) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? coin['color'] : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.monetization_on, color: coin['color'], size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        coin['name'].split(' ')[1], // 显示简称 BTC, ETH, ADA, SOL
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: coin['color'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 策略参数
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('策略参数', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 策略说明
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('两周定投策略设置',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                            SizedBox(height: 8),
                            Text('• 两周定投: \$2000', style: TextStyle(fontSize: 12)),
                            Text('• 投资频率: 每两周一次', style: TextStyle(fontSize: 12)),
                            Text('• 投资时间: 每两周第一天', style: TextStyle(fontSize: 12)),
                            Text('• 回测周期: 最近1年数据 (约26个两周周期)', style: TextStyle(fontSize: 12)),
                            Text('• 策略类型: 定期定额投资', style: TextStyle(fontSize: 12)),
                            Text('• 数据来源: 币安API (日K线)', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 执行回测按钮
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isLoadingBacktest.value ? null : controller.runBacktest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: controller.isLoadingBacktest.value
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('执行${controller.getCoinName(controller.selectedCoin.value)}最近1年两周定投回测'),
                            )),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 回测结果
              Obx(() {
                if (controller.backtestResult?.isNotEmpty == true) {
                  final result = controller.backtestResult!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${result['coinName']} 最近1年两周定投回测结果',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildResultRow('回测周期', result['period']),
                          _buildResultRow('实际周期数', '${result['periods']}个两周周期'),
                          _buildResultRow('总本钱', '\$${result['totalInvested'].toStringAsFixed(2)}'),
                          _buildResultRow('累计买入数量', '${result['totalCoins'].toStringAsFixed(6)}'),
                          _buildResultRow('当前价格', '\$${result['currentPrice'].toStringAsFixed(2)}'),
                          _buildResultRow('总收益', '\$${result['totalProfit'].toStringAsFixed(2)}'),
                          _buildResultRow(
                              '本钱加收益', '\$${(result['totalInvested'] + result['totalProfit']).toStringAsFixed(2)}'),
                          _buildResultRow('收益率', '${result['profitPercentage'].toStringAsFixed(2)}%'),
                          _buildResultRow('交易次数', '${result['tradeCount']}次'),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 16),

              // 交易记录
              Obx(() {
                if (controller.backtestResult?.isNotEmpty == true && controller.backtestResult!['trades'].isNotEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('最近1年两周定投记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 500,
                            child: ListView.builder(
                              itemCount: controller.backtestResult!['trades'].length,
                              itemBuilder: (context, index) {
                                final trade = controller.backtestResult!['trades'][index];
                                return ListTile(
                                  title: Text('第${trade['period']}个两周周期 - ${trade['date']}'),
                                  subtitle: Text(
                                    '价格: \$${trade['price'].toStringAsFixed(2)} | RSI: ${trade['rsi'].toStringAsFixed(1)} | 金额: \$${trade['amount'].toStringAsFixed(2)}',
                                  ),
                                  trailing: Text('${trade['type']}',
                                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child:
                                        Text('${trade['period']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 结果行显示
  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
