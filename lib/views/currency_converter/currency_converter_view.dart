import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'currency_converter_controller.dart';

class CurrencyConverterView extends GetView<CurrencyConverterController> {
  const CurrencyConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汇率换算'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 输入金额
            _buildAmountInputCard(),
            const SizedBox(height: 8),
            // 货币选择
            _buildCurrencySelectionCard(),
            const SizedBox(height: 8),
            // 转换结果
            _buildResultCard(),
            const SizedBox(height: 8),
            // 操作按钮
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // 构建金额输入卡片
  Widget _buildAmountInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('输入金额', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Obx(() {
              final fromCurrencyInfo = controller.getCurrencyInfo(controller.fromCurrency.value);
              return TextField(
                controller: controller.amountController,
                keyboardType: TextInputType.number,
                onChanged: (value) => controller.fetchExchangeRate(),
                decoration: InputDecoration(
                  hintText: '请输入要换算的金额',
                  prefixText: '${fromCurrencyInfo?['symbol']} ',
                  prefixStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 构建货币选择卡片
  Widget _buildCurrencySelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 从货币
            Obx(() => _buildCurrencySelector(
                  '从',
                  controller.fromCurrency.value,
                  (currency) {
                    controller.fromCurrency.value = currency;
                    controller.fetchExchangeRate();
                  },
                )),
            const SizedBox(height: 8),
            // 交换按钮
            Center(
              child: IconButton(
                onPressed: controller.swapCurrencies,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_vert, color: Colors.blue, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 到货币
            Obx(() => _buildCurrencySelector(
                  '到',
                  controller.toCurrency.value,
                  (currency) {
                    controller.toCurrency.value = currency;
                    controller.fetchExchangeRate();
                  },
                )),
          ],
        ),
      ),
    );
  }

  // 构建货币选择器
  Widget _buildCurrencySelector(String label, String selectedCurrency, Function(String) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedCurrency,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: controller.currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency['code'],
                child: Row(
                  children: [
                    Text(currency['flag'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(currency['code'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text(currency['name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }

  // 构建结果卡片
  Widget _buildResultCard() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text('正在获取汇率...', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600], size: 32),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      if (controller.convertedAmount.value > 0) {
        final toCurrencyInfo = controller.getCurrencyInfo(controller.toCurrency.value);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '${controller.amountController.text} ${controller.fromCurrency.value} =',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '${toCurrencyInfo?['flag']} ${controller.formatAmount(controller.convertedAmount.value)} ${controller.toCurrency.value}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '汇率: 1 ${controller.fromCurrency.value} = ${controller.formatAmount(controller.exchangeRate.value)} ${controller.toCurrency.value}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.currency_exchange, color: Colors.grey[400], size: 32),
              const SizedBox(height: 8),
              Text(
                '输入金额开始换算',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.clearInput,
            icon: const Icon(Icons.clear),
            label: const Text('清空'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() => ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : controller.fetchExchangeRate,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(controller.isLoading.value ? '获取中...' : '刷新汇率'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              )),
        ),
      ],
    );
  }
}
