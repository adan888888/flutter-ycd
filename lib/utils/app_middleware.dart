import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';
import 'network/get_store.dart';

/// 第一次欢迎页面
class AppMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    GetStore.getInstance().checkLoginStatus();
    bool isLogin = GetStore.getInstance().isLogin;
    if (!isLogin) {
      return null;
    } else {
      return const RouteSettings(name: AppRoutes.home);
    }
  }
}
