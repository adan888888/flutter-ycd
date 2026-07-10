import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/utils/network/api_session_handler.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/permission_util.dart';
import 'package:ycd/utils/user_role.dart';

// 首页选择界面
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    // 仅「先去逛逛」未登录进入时显示返回；登录后进首页不显示
    final showBack = !store.isLogin;
    final displayName = _resolveDisplayName(store);

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
                    ApiSessionHandler.goLogin();
                  }
                },
              )
            : null,
        iconTheme: const IconThemeData(color: Color(0xFF2F3A4F)),
        title: const Text(
          '投资分析工具 🔧',
          style: TextStyle(color: Color(0xFF2F3A4F), fontSize: 18),
        ),
        centerTitle: true,
        actions: store.isLogin
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF2F3A4F), size: 22),
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    if (value == 'logout') _confirmLogout();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18, color: Color(0xFF2F3A4F)),
                          SizedBox(width: 8),
                          Text('退出登录'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              if (store.isLogin) ...[
                _buildUserInfoRow(displayName, store),
                const SizedBox(height: 8),
              ],
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

              _buildProOptionCard(
                context,
                icon: Icons.receipt_long,
                title: '持币记录分析',
                subtitle: '查看当前登录用户的买入记录',
                color: Colors.purple,
                route: AppRoutes.buyRecords,
              ),

              const SizedBox(height: 4),

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

              // AES加解密工具选项（专业版及以上）
              _buildProOptionCard(
                context,
                icon: Icons.vpn_key,
                title: 'AES加解密工具',
                subtitle: 'AES加密和解密工具',
                color: Colors.deepOrange,
                route: AppRoutes.aesEncrypt,
              ),

              const SizedBox(height: 4),

              _buildProOptionCard(
                context,
                icon: Icons.lock,
                title: '数字密码本',
                subtitle: '安全存储和管理密码',
                color: Colors.indigo,
                route: AppRoutes.digitalPasswordBook,
              ),

              const SizedBox(height: 4),

              // 百家乐开奖模拟选项 - 倒数第二（专业版及以上）
              _buildProOptionCard(
                context,
                icon: Icons.casino,
                title: '百家乐开奖模拟',
                subtitle: '模拟真实的开奖过程',
                color: Colors.amber,
                route: AppRoutes.baccaratSimulation,
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
                onTap: () => Get.toNamed(AppRoutes.jiShuQiHome),
              ),

              const SizedBox(height: 20), // 底部留白
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow(String displayName, GetStore store) {
    return Row(
      children: [
        Flexible(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2F3A4F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 1),
        _buildRoleBadge(store),
      ],
    );
  }

  String _resolveDisplayName(GetStore store) {
    if (!store.isLogin) return '';
    final user = store.userModel;
    if (user.nickname.trim().isNotEmpty) return user.nickname.trim();
    if (user.account.trim().isNotEmpty) return user.account.trim();
    if (user.userId.isNotEmpty) return '用户${user.userId}';
    return '已登录';
  }

  Widget _buildRoleBadge(GetStore store) {
    final user = store.userModel;
    final role = user.isSuperAdmin ? UserRole.superAdmin : UserRole.normalize(user.role);
    final label = UserRole.label(role);

    late Color bg;
    late Color fg;
    switch (role) {
      case UserRole.superAdmin:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
      case UserRole.pro:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      default:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF546E7A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }

  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定退出当前账号？'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Get.back();
              await GetStore.getInstance().logout();
              ApiSessionHandler.goLogin();
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  /// 专业版及以上功能入口：未登录或普通用户显示锁定态
  Widget _buildProOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    final canAccess = PermissionUtil.canAccessProFeature();
    return _buildOptionCard(
      context,
      icon: canAccess ? icon : Icons.lock_outline,
      title: title,
      subtitle: canAccess ? subtitle : PermissionUtil.proFeatureLockedSubtitle(isLogin: store.isLogin),
      color: canAccess ? color : Colors.grey,
      onTap: () {
        if (!canAccess) {
          if (!store.isLogin) {
            BXLoading.showToast('请先登录');
            BXLoading.reset();
            Get.toNamed(AppRoutes.login);
            return;
          }
          BXLoading.showError(toast: '该功能需专业版及以上权限，请联系管理员');
          return;
        }
        Get.toNamed(route);
      },
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
