import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart'; // 导入新的路由配置
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
