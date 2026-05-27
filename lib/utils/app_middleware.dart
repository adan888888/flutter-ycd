import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart'; // 导入新的路由配置
import 'network/get_store.dart';

/// 第一次欢迎页面
class AppMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    bool isLogin = GetStore.getInstance().isLogin;
    if (!isLogin) {
      return null;
    }
    final user = GetStore.getInstance().readUserModel();
    if (user.canUseYcd) {
      return const RouteSettings(name: AppRoutes.home);
    }
    // 已登录但 ycd 已到期：清除会话并留在登录页
    GetStore.getInstance().cleanUser();
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
    final user = GetStore.getInstance().readUserModel();
    if (!user.canUseYcd) {
      GetStore.getInstance().cleanUser();
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// 仅超级管理员可访问（需先登录且 ycd 有效）
class SuperAdminRequiredMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    if (!GetStore.getInstance().isLogin) {
      return const RouteSettings(name: AppRoutes.login);
    }
    final user = GetStore.getInstance().readUserModel();
    if (!user.canUseYcd) {
      GetStore.getInstance().cleanUser();
      return const RouteSettings(name: AppRoutes.login);
    }
    if (!user.isSuperAdmin) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
