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
          '数据策略分析工具 🔧',
          style: TextStyle(color: Color(0xFF2F3A4F), fontSize: 18),
        ),
        centerTitle: true,
        actions: store.isLogin
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF2F3A4F), size: 22),
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    if (value == 'logout') _confirmLogout();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout,
                              size: 18, color: Color(0xFF2F3A4F)),
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
            top: MediaQuery.of(context).padding.top +
                kToolbarHeight, // 动态获取 AppBar 高度
            left: 14.0,
            right: 14.0,
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _staggered(0, _buildHeaderPanel(store, displayName)),

              const SizedBox(height: 18),

              _staggered(
                1,
                // 资金管理工具：首页主推入口，用渐变大卡与其它工具拉开层次
                _buildFeaturedCard(
                  imagePath: 'assets/images/temp_dice.png',
                  title: '资金管理工具',
                  subtitle: '帮你分析游戏数据',
                  onTap: () => Get.toNamed(AppRoutes.jiShuQiHome),
                ),
              ),

              const SizedBox(height: 18),

              _staggered(2, _buildSectionLabel('全部工具')),

              const SizedBox(height: 10),

              ..._buildToolCards(context).asMap().entries.map(
                    (entry) => _staggered(entry.key + 3, entry.value),
                  ),

              const SizedBox(height: 20), // 底部留白
            ],
          ),
        ),
      ),
    );
  }

  /// 列表整体的入场动画：按位置递增时长，形成自上而下的浮现效果
  Widget _staggered(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 55),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }

  /// 顶部欢迎面板：登录态显示头像与角色，未登录提示去登录
  Widget _buildHeaderPanel(GetStore store, String displayName) {
    final isLogin = store.isLogin;
    final title = isLogin ? displayName : '未登录';
    final avatarLetter =
        isLogin && displayName.isNotEmpty ? displayName.characters.first : '?';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF394B70), Color(0xFF63799F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF394B70).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
            ),
            child: Text(
              avatarLetter.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLogin ? '欢迎回来' : '欢迎使用',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isLogin) ...[
                      const SizedBox(width: 6),
                      _buildRoleBadge(store),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/polyline.png',
            width: 92,
            height: 52,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF63799F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2F3A4F),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  /// 主推入口：与普通卡片同为浅色玻璃卡，靠更大的尺寸与「常用」标签突出
  Widget _buildFeaturedCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    const accent = Color(0xFFE0484D);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.42),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF2F3A4F).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.95),
                        accent.withValues(alpha: 0.58),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(imagePath, fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF2B3445),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              '常用',
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A879C),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildToolCards(BuildContext context) {
    return [
      _buildOptionCard(
        context,
        icon: Icons.calculate,
        title: '复利投资计算器',
        subtitle: '计算复利收益',
        color: Colors.blue,
        onTap: () => Get.toNamed(AppRoutes.investmentCalculator),
      ),
      _buildOptionCard(
        context,
        icon: Icons.trending_up,
        title: '多币种 RSI 分析',
        subtitle: '分析相对强弱指数',
        color: Colors.green,
        onTap: () => Get.toNamed(AppRoutes.rsiAnalysis),
      ),
      _buildOptionCard(
        context,
        icon: Icons.schedule,
        title: '每周定投回测',
        subtitle: '回测定投策略',
        color: Colors.orange,
        onTap: () => Get.toNamed(AppRoutes.rsiStrategyBacktest),
      ),
      _buildProOptionCard(
        context,
        icon: Icons.receipt_long,
        title: '持币记录分析',
        subtitle: '查看当前登录用户的买入记录',
        color: Colors.purple,
        route: AppRoutes.buyRecords,
      ),
      _buildOptionCard(
        context,
        icon: Icons.currency_exchange,
        title: '汇率换算',
        subtitle: '实时汇率换算工具',
        color: Colors.teal,
        onTap: () => Get.toNamed(AppRoutes.currencyConverter),
      ),
      _buildProOptionCard(
        context,
        icon: Icons.vpn_key,
        title: 'AES加解密工具',
        subtitle: 'AES加密和解密工具',
        color: Colors.deepOrange,
        route: AppRoutes.aesEncrypt,
      ),
      _buildProOptionCard(
        context,
        icon: Icons.lock,
        title: '数字密码本',
        subtitle: '安全存储和管理密码',
        color: Colors.indigo,
        route: AppRoutes.digitalPasswordBook,
      ),
      _buildProOptionCard(
        context,
        icon: Icons.casino,
        title: '百家乐开奖模拟',
        subtitle: '模拟真实的开奖过程',
        color: Colors.amber,
        route: AppRoutes.baccaratSimulation,
      ),
    ];
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
    final role =
        user.isSuperAdmin ? UserRole.superAdmin : UserRole.normalize(user.role);
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
      subtitle: canAccess
          ? subtitle
          : PermissionUtil.proFeatureLockedSubtitle(isLogin: store.isLogin),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.48),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          // 主阴影带上入口自身的主题色，让整列卡片有彩色辉光
          BoxShadow(
            color: color.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF2F3A4F).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withValues(alpha: 0.10),
          highlightColor: color.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.95),
                        color.withValues(alpha: 0.58),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.32),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        )
                      : Icon(icon, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B3445),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A879C),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
