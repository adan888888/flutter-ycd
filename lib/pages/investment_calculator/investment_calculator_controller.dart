import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvestmentCalculatorController extends GetxController {
  // 表单控制器
  final TextEditingController initialAmountController = TextEditingController();
  final TextEditingController monthlyController = TextEditingController();
  final TextEditingController yearsController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();

  // 状态变量
  final RxDouble totalAmount = 0.0.obs;
  final RxDouble totalPrincipal = 0.0.obs;
  final RxDouble totalInterest = 0.0.obs;
  final RxString calculationMethod = 'compound'.obs; // compound or simple

  @override
  void onClose() {
    initialAmountController.dispose();
    monthlyController.dispose();
    yearsController.dispose();
    interestRateController.dispose();
    super.onClose();
  }

  // 计算投资收益
  void calculateInvestment() {
    try {
      final initialAmount = double.parse(initialAmountController.text.isEmpty
          ? '0'
          : initialAmountController.text);
      final monthlyInvestment = double.parse(
          monthlyController.text.isEmpty ? '0' : monthlyController.text);
      final years = double.parse(
          yearsController.text.isEmpty ? '0' : yearsController.text);
      final annualRate = double.parse(interestRateController.text.isEmpty
              ? '0'
              : interestRateController.text) /
          100;

      if (calculationMethod.value == 'compound') {
        _calculateCompoundInterest(
            initialAmount, monthlyInvestment, years, annualRate);
      } else {
        _calculateSimpleInterest(
            initialAmount, monthlyInvestment, years, annualRate);
      }
    } catch (e) {
      // 重置结果
      totalAmount.value = 0.0;
      totalPrincipal.value = 0.0;
      totalInterest.value = 0.0;
    }
  }

  // 复利计算
  void _calculateCompoundInterest(
      double initial, double monthly, double years, double rate) {
    final monthlyRate = rate / 12;
    final months = years * 12;

    // 初始投资的复利
    final initialFutureValue = initial * _pow(1 + monthlyRate, months);

    // 每月投资的复利 (年金现值公式)
    double monthlyFutureValue = 0;
    if (monthlyRate > 0) {
      monthlyFutureValue =
          monthly * ((_pow(1 + monthlyRate, months) - 1) / monthlyRate);
    } else {
      monthlyFutureValue = monthly * months;
    }

    totalAmount.value = initialFutureValue + monthlyFutureValue;
    totalPrincipal.value = initial + (monthly * months);
    totalInterest.value = totalAmount.value - totalPrincipal.value;
  }

  // 简单利息计算
  void _calculateSimpleInterest(
      double initial, double monthly, double years, double rate) {
    final totalPrincipalAmount = initial + (monthly * years * 12);
    final simpleInterest = totalPrincipalAmount * rate * years;

    totalPrincipal.value = totalPrincipalAmount;
    totalInterest.value = simpleInterest;
    totalAmount.value = totalPrincipal.value + totalInterest.value;
  }

  // 幂运算辅助函数
  double _pow(double base, double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return base;

    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  // 清空输入
  void clearAll() {
    initialAmountController.clear();
    monthlyController.clear();
    yearsController.clear();
    interestRateController.clear();
    totalAmount.value = 0.0;
    totalPrincipal.value = 0.0;
    totalInterest.value = 0.0;
  }

  // 格式化货币显示
  String formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }
}
