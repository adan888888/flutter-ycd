import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 首页选择界面
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('百家乐模拟器'), backgroundColor: Theme.of(context).colorScheme.inversePrimary, centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.show_chart_sharp, size: 100, color: Color.fromARGB(150, 104, 57, 88)),
            const Text('选择您需要的功能', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),

            // 投资计算器选项
            _buildOptionCard(
              context,
              icon: Icons.calculate,
              title: '复利投资计算器',
              subtitle: '计算复利收益',
              color: Colors.blue,
              onTap: () {
                Get.toNamed('/investment-calculator');
              },
            ),

            const SizedBox(height: 4),
            // RSI分析选项
            _buildOptionCard(
              context,
              icon: Icons.trending_up,
              title: '多币种 RSI 分析',
              subtitle: '分析相对强弱指数',
              color: Colors.green,
              onTap: () {
                Get.toNamed('/rsi-analysis');
              },
            ),

            const SizedBox(height: 4),

            // 每周定投回测选项
            _buildOptionCard(
              context,
              icon: Icons.schedule,
              title: '每周定投回测',
              subtitle: '回测定投策略',
              color: Colors.orange,
              onTap: () {
                Get.toNamed('/rsi-strategy-backtest');
              },
            ),

            const SizedBox(height: 4),

            // 买入记录选项
            _buildOptionCard(
              context,
              icon: Icons.receipt_long,
              title: '持币记录分析',
              subtitle: '查看历史买入记录',
              color: Colors.purple,
              onTap: () {
                Get.toNamed('/buy-records');
              },
            ),

            const SizedBox(height: 4),

            // 汇率换算选项
            _buildOptionCard(
              context,
              icon: Icons.currency_exchange,
              title: '汇率换算',
              subtitle: '实时汇率换算工具',
              color: Colors.teal,
              onTap: () {
                Get.toNamed('/currency-converter');
              },
            ),

            const SizedBox(height: 4),

            // 百家乐游戏选项 - 移到最后一个
            _buildOptionCard(
              context,
              icon: Icons.games,
              imagePath: 'assets/images/temp_dice.png', // 添加图片路径
              title: '百家乐游戏',
              subtitle: '体验真实的游戏乐趣',
              color: Colors.red,
              onTap: () {
                // 检查登录状态，如果未登录则跳转到登录页
                Get.toNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context,
      {required IconData icon,
      String? imagePath, // 添加可选的图片路径参数
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 75, // 从85改为75，减少卡片高度
          padding: const EdgeInsets.all(14), // 从16改为14，减少内部间距
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // 从12改为10，减少图标容器间距
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, size: 26, color: color), // 从28改为26，稍微减小图标
              ),
              const SizedBox(width: 14), // 从16改为14，减少图标和文字间距
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), // 从18改为17
                    const SizedBox(height: 3), // 从4改为3，减少标题和副标题间距
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])), // 从13改为12
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16), // 从18改为16
            ],
          ),
        ),
      ),
    );
  }
}
