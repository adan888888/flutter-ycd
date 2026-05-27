import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/network/get_store.dart';

// 首页选择界面
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    // 仅「先去逛逛」未登录进入时显示返回；登录后进首页不显示
    final showBack = !store.isLogin;
    final isSuperAdmin = store.isLogin && store.readUserModel().isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (Get.key.currentState?.canPop() ?? false) {
                    Get.back();
                  } else {
                    Get.offAllNamed(AppRoutes.login);
                  }
                },
              )
            : null,
        iconTheme: const IconThemeData(color: Color(0xFF2F3A4F)),
        title: const Text(
          '投资分析工具🔧',
          style: TextStyle(color: Color(0xFF2F3A4F)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // 让 body 扩展到 AppBar 背后
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight, // 动态获取 AppBar 高度
            left: 14.0,
            right: 14.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/polyline.png',
                width: 150,
                height: 80,
                fit: BoxFit.cover,
              ),
              _buildOptionCard(
                context,
                icon: Icons.calculate,
                title: '复利投资计算器',
                subtitle: '计算复利收益',
                color: Colors.blue,
                onTap: () => Get.toNamed(AppRoutes.investmentCalculator),
              ),

              const SizedBox(height: 4),
              // RSI分析选项
              _buildOptionCard(
                context,
                icon: Icons.trending_up,
                title: '多币种 RSI 分析',
                subtitle: '分析相对强弱指数',
                color: Colors.green,
                onTap: () => Get.toNamed(AppRoutes.rsiAnalysis),
              ),

              const SizedBox(height: 4),

              // 每周定投回测选项
              _buildOptionCard(
                context,
                icon: Icons.schedule,
                title: '每周定投回测',
                subtitle: '回测定投策略',
                color: Colors.orange,
                onTap: () => Get.toNamed(AppRoutes.rsiStrategyBacktest),
              ),

              const SizedBox(height: 4),

              if (isSuperAdmin) ...[
                // 买入记录选项（仅超级管理员）
                _buildOptionCard(
                  context,
                  icon: Icons.receipt_long,
                  title: '持币记录分析',
                  subtitle: '查看历史买入记录',
                  color: Colors.purple,
                  onTap: () => Get.toNamed(AppRoutes.buyRecords),
                ),

                const SizedBox(height: 4),
              ],

              // 汇率换算选项
              _buildOptionCard(
                context,
                icon: Icons.currency_exchange,
                title: '汇率换算',
                subtitle: '实时汇率换算工具',
                color: Colors.teal,
                onTap: () => Get.toNamed(AppRoutes.currencyConverter),
              ),

              const SizedBox(height: 4),

              // AES加解密工具选项
              _buildOptionCard(
                context,
                icon: Icons.vpn_key,
                title: 'AES加解密工具',
                subtitle: 'AES加密和解密工具',
                color: Colors.deepOrange,
                onTap: () => Get.toNamed(AppRoutes.aesEncrypt),
              ),

              const SizedBox(height: 4),

              if (isSuperAdmin) ...[
                // 数字密码本选项（仅超级管理员）
                _buildOptionCard(
                  context,
                  icon: Icons.lock,
                  title: '数字密码本',
                  subtitle: '安全存储和管理密码',
                  color: Colors.indigo,
                  onTap: () => Get.toNamed(AppRoutes.digitalPasswordBook),
                ),

                const SizedBox(height: 4),
              ],

              // 百家乐开奖模拟选项 - 倒数第二
              _buildOptionCard(
                context,
                icon: Icons.casino,
                title: '百家乐开奖模拟',
                subtitle: '模拟真实的开奖过程',
                color: Colors.amber,
                onTap: () => Get.toNamed(AppRoutes.baccaratSimulation),
              ),

              const SizedBox(height: 4),

              // 百家乐游戏选项 - 最后面
              _buildOptionCard(
                context,
                icon: Icons.games,
                imagePath: 'assets/images/temp_dice.png',
                title: '计数器',
                subtitle: '让你游戏数据更加清晰',
                color: Colors.red,
                onTap: () => Get.toNamed(AppRoutes.gameHome),
              ),

              const SizedBox(height: 20), // 底部留白
            ],
          ),
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
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ), // 从18改为17
                    const SizedBox(height: 3), // 从4改为3，减少标题和副标题间距
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ), // 从13改为12
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ), // 从18改为16
            ],
          ),
        ),
      ),
    );
  }
}
