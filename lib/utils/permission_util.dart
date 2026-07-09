import 'package:get/get.dart';

import '../routes/app_routes.dart';
import 'bx_loading.dart';
import 'network/api_session_handler.dart';
import 'network/get_store.dart';

/// 专业版及以上功能权限校验
abstract final class PermissionUtil {
  static bool canAccessProFeature() {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    return store.isLogin && store.userModel.isProOrAbove;
  }

  /// 控制器/页面内二次校验；无权限时 Toast 并返回 false
  static bool guardProFeature() {
    final store = GetStore.getInstance();
    store.checkLoginStatus();
    if (!store.isLogin) {
      BXLoading.showToast('请先登录');
      Future.microtask(() {
        ApiSessionHandler.goLogin();
      });
      return false;
    }
    if (!store.userModel.isProOrAbove) {
      BXLoading.showToast('该功能需专业版及以上权限，请联系管理员');
      Future.microtask(() {
        if (Get.currentRoute != AppRoutes.home) {
          Get.offAllNamed(AppRoutes.home);
        }
      });
      return false;
    }
    return true;
  }

  static String proFeatureLockedSubtitle({required bool isLogin}) {
    if (!isLogin) return '请先登录，需专业版及以上权限';
    return '需专业版，请联系管理员';
  }
}
