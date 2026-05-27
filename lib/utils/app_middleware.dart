import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart'; // 导入新的路由配置
import 'bx_loading.dart';
import 'network/get_store.dart';

/// 第一次欢迎页面
class AppMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    final isLogin = GetStore.getInstance().isLogin;
    if (isLogin) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}

/// 受保护页面中间件：未登录先跳登录页
class AuthRequiredMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    final isLogin = GetStore.getInstance().isLogin;
    if (!isLogin) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// 专业版及以上功能：未登录跳登录；普通用户拒绝访问
class ProFeatureMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    final store = GetStore.getInstance();
    if (!store.isLogin) {
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!store.userModel.isProOrAbove) {
      BXLoading.showToast('该功能需专业版及以上权限，请联系管理员');
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
