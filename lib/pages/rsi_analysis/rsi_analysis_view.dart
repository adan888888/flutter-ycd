import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'rsi_analysis_controller.dart';

class RSIAnalysisView extends GetView<RSIAnalysisController> {
  const RSIAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('${controller.getCoinName(controller.selectedCoin.value)} RSI 分析')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RSI计算选项
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RSI 6日计算', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 币种选择
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

                      const SizedBox(height: 16),

                      // 自定义价格开关
                      Obx(() => Row(
                            children: [
                              Checkbox(
                                value: controller.useCustomPrice.value,
                                onChanged: (value) => controller.toggleCustomPrice(value ?? false),
                              ),
                              const Text('使用自定义价格'),
                            ],
                          )),

                      // 自定义价格输入框
                      Obx(() {
                        if (controller.useCustomPrice.value) {
                          return Column(
                            children: [
                              const SizedBox(height: 8),
                              TextField(
                                controller: controller.customPriceController,
                                decoration: const InputDecoration(
                                  labelText: '假设价格 (美元)',
                                  border: OutlineInputBorder(),
                                  hintText: '例如: 100000',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => ElevatedButton(
                              onPressed: controller.isLoadingRsi.value ? null : controller.calculateRSI,
                              child: controller.isLoadingRsi.value
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('计算${controller.getCoinName(controller.selectedCoin.value)} RSI 6日'),
                            )),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // RSI结果显示
              Obx(() {
                if (controller.rsiResult?.isNotEmpty == true) {
                  final result = controller.rsiResult!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result['isCustomPrice']
                                ? '${controller.getCoinName(controller.selectedCoin.value)} RSI 6日分析 (自定义价格)'
                                : '${controller.getCoinName(controller.selectedCoin.value)} RSI 6日分析 (实时价格)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildSimpleRow('当前价格', '\$${result['currentPrice'].toStringAsFixed(2)}'),
                          _buildSimpleRow('RSI 6日', '${result['rsi'].toStringAsFixed(2)}'),
                          _buildSimpleRow('市场状态', result['status']),
                          _buildSimpleRow('更新时间', result['timestamp'].toString().substring(0, 19)),
                          if (result['isCustomPrice'])
                            _buildSimpleRow('价格类型', '假设价格')
                          else
                            _buildSimpleRow('价格类型', '实时价格'),
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

  // 简单的行显示
  Widget _buildSimpleRow(String label, String value) {
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
