import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'investment_calculator_controller.dart';

class InvestmentCalculatorView extends GetView<InvestmentCalculatorController> {
  const InvestmentCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投资计算器'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 输入表单
            _buildInputForm(),
            const SizedBox(height: 20),
            // 计算按钮
            _buildCalculateButton(),
            const SizedBox(height: 20),
            // 结果显示
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '投资参数',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: controller.initialAmountController,
              label: '初始投资金额',
              hint: '请输入初始投资金额',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.monthlyController,
              label: '每月投资金额',
              hint: '请输入每月投资金额',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.yearsController,
              label: '投资年限',
              hint: '请输入投资年限',
              suffix: '年',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: controller.interestRateController,
              label: '年收益率',
              hint: '请输入年收益率',
              suffix: '%',
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    const Text('计算方式: '),
                    Radio<String>(
                      value: 'compound',
                      groupValue: controller.calculationMethod.value,
                      onChanged: (value) => controller.calculationMethod.value = value!,
                    ),
                    const Text('复利'),
                    Radio<String>(
                      value: 'simple',
                      groupValue: controller.calculationMethod.value,
                      onChanged: (value) => controller.calculationMethod.value = value!,
                    ),
                    const Text('单利'),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => this.controller.calculateInvestment(),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.clearAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('清空'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.calculateInvestment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('计算'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Obx(() => Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '计算结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildResultItem(
                  '总投资本金',
                  controller.formatCurrencyWithChinese(controller.totalPrincipal.value),
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildResultItem(
                  '预期收益',
                  controller.formatCurrencyWithChinese(controller.totalInterest.value),
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildResultItem(
                  '总金额',
                  controller.formatCurrencyWithChinese(controller.totalAmount.value),
                  Colors.purple,
                ),
                const SizedBox(height: 8),
                _buildResultItem(
                  '翻倍数',
                  '${controller.getMultiplier().toStringAsFixed(2)}倍',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
