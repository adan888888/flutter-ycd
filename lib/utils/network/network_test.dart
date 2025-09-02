import 'package:flutter/material.dart';
import 'http_service.dart';
import 'api.dart';
import '../../model/user_model.dart';

class NetworkTest {
  static void testDioService() {
    debugPrint('🧪 开始测试Dio网络服务...');

    // 测试POST请求
    HttpService.getInstance().post<UserModel>(
      Api.login,
      params: {"username": "admin1", "password": "123"},
      success: (isSuccess, code, message, results) {
        debugPrint('✅ 登录成功: $message');
        debugPrint('📊 返回数据: ${results.length} 条');
        if (results.isNotEmpty) {
          debugPrint('👤 用户信息: ${results.first.toJson()}');
        }
      },
      failed: (error, model) {
        debugPrint('❌ 登录失败: $error');
        debugPrint('🔍 错误详情: ${model.msg}');
      },
      onModel: (json) => UserModel.fromJson(json),
      isShowLoading: false, // 测试时不显示loading
    );
  }

  static void testConnection() {
    debugPrint('🔗 测试网络连接...');

    // 简单的GET请求测试
    HttpService.getInstance().get<dynamic>(
      '/',
      success: (isSuccess, code, message, results) {
        debugPrint('✅ 连接成功: $message');
      },
      failed: (error, model) {
        debugPrint('❌ 连接失败: $error');
      },
      isShowLoading: false,
    );
  }
}
