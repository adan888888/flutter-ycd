import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/my_widget/review_approved_dialog.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/network/api_session_handler.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/permission_util.dart';
import 'package:ycd/utils/user_role.dart';

// 首页选择界面
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // Figma bg_hall_full_screen 底色 / 金点缀，统一深色大厅风格
  static const Color _hallBg = Color(0xFF222124);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _cardFill = Color(0xE62A292E); // ~90% 不透明深灰，挡住背景噪点
  static const Color _cardBorder = Color(0x66D4AF37); // 金色描边

  @override
  Widget build(BuildContext context) {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    // 仅「先去逛逛」未登录进入时显示返回；登录后进首页不显示
    final showBack = !store.isLogin;
    final displayName = _resolveDisplayName(store);

    return Scaffold(
      backgroundColor: _hallBg,
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const SizedBox.shrink(),
        centerTitle: true,
        actions: store.isLogin
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      // 让 body 扩展到 AppBar 背后
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          color: _hallBg,
          image: DecorationImage(
            image: AssetImage('assets/images/home_bg.webp'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            // 中下部渐变遮罩：保留顶部龙纹，压暗列表区背景噪点
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33222124),
                      Color(0xCC222124),
                      Color(0xF2222124),
                    ],
                    stops: [0.0, 0.38, 0.72],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                left: 14.0,
                right: 14.0,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _staggered(0, _buildHeaderPanel(store, displayName)),
                  const SizedBox(height: 18),
                  _staggered(
                    1,
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
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
    final avatarLetter = isLogin && displayName.isNotEmpty ? displayName.characters.first : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
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
                    color: Colors.white.withValues(alpha: 0.72),
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
          Opacity(
            opacity: 0.85,
            child: Image.asset(
              'assets/images/polyline.png',
              width: 74,
              height: 42,
              fit: BoxFit.contain,
            ),
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
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  /// 主推入口：深色玻璃卡片 + 金色「推荐」点缀。
  Widget _buildFeaturedCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cardFill,
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: _gold.withValues(alpha: 0.12),
          highlightColor: _gold.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 49,
                  height: 49,
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
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildToolBadge('推荐'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
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
                    color: _gold.withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: _gold,
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
    final role = user.isSuperAdmin ? UserRole.superAdmin : UserRole.normalize(user.role);
    final label = UserRole.label(role);

    late Color bg;
    late Color fg;
    switch (role) {
      case UserRole.superAdmin:
        bg = const Color(0x33C62828);
        fg = const Color(0xFFFF8A80);
      case UserRole.pro:
        bg = _gold.withValues(alpha: 0.16);
        fg = _gold;
      default:
        bg = Colors.white.withValues(alpha: 0.10);
        fg = Colors.white.withValues(alpha: 0.75);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withValues(alpha: 0.45)),
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
    Get.dialog<void>(
      ReviewApprovedDialog(
        title: '退出登录',
        message: '确定退出当前账号？',
        badgeText: '退出后需重新登录',
        buttonText: '退出',
        secondaryButtonText: '取消',
        statusIcon: Icons.logout_rounded,
        onConfirmed: () async {
          await GetStore.getInstance().logout();
          ApiSessionHandler.goLogin();
        },
      ),
      barrierColor: Colors.black.withValues(alpha: 0.50),
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
      locked: !canAccess,
      onTap: () {
        if (!canAccess) {
          if (!store.isLogin) {
            Get.dialog<void>(
              ReviewApprovedDialog(
                title: '请先登录',
                message: '登录后即可使用$title及其他专业功能',
                badgeText: '登录状态受安全保护',
                buttonText: '去登录',
                statusIcon: Icons.person_outline_rounded,
                onConfirmed: () => Get.toNamed(AppRoutes.login),
              ),
              barrierColor: Colors.black.withValues(alpha: 0.50),
            );
            return;
          }
          Get.dialog<void>(
            const ReviewApprovedDialog(
              title: '需要专业权限',
              message: '该功能仅对专业版及以上用户开放\n请联系管理员升级账户权限',
              badgeText: '升级后即可正常使用',
              statusIcon: Icons.lock_outline_rounded,
            ),
            barrierColor: Colors.black.withValues(alpha: 0.50),
          );
          return;
        }
        Get.toNamed(route);
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    String? imagePath,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: _cardFill,
        border: Border.all(
          color: badge != null ? _gold.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          splashColor: color.withValues(alpha: 0.14),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                if (imagePath != null)
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  )
                else
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
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 24, color: Colors.white),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: locked ? Colors.white.withValues(alpha: 0.55) : Colors.white,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            _buildToolBadge(badge),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: locked ? 0.35 : 0.52),
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
                    color: color.withValues(alpha: 0.22),
                  ),
                  child: Icon(
                    locked ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
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

  Widget _buildToolBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
