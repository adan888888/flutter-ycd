import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/model/user_model.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/network/http_mgr.dart';

import 'login_state.dart';

class LoginController extends GetxController {
  final LoginState state = LoginState();

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 切换密码可见性
  void togglePasswordVisibility() {
    state.isPasswordVisible.value = !state.isPasswordVisible.value;
  }

  Future<void> login() async {
    /*
    formKey.currentState!.validate()
    验证：
    用户名不能为空
    密码不能为空
    密码长度至少 2 位
    只有以上三项都通过，validate() 才返回 true，登录流程才会继续。
     */
    if (formKey.currentState!.validate()) {
      // 设置加载状态
      state.isLoading.value = true;

      String usrname = userNameController.text;
      String password = passwordController.text;

      try {
        // 真实登录逻辑
        BXPost<UserModel>(Api.login,
            params: {"username": usrname, "password": password},
            success: (isSuccess, code, message, results) {
              if (isSuccess) {
                final user = results.first;
                GetStore.getInstance().saveUser(user);
                if (user.userId.isEmpty) {
                  Get.snackbar('登录失败', '用户数据异常', snackPosition: SnackPosition.TOP);
                  return;
                }
                if (user.canUseYcd) {
                  Get.offAndToNamed(AppRoutes.gameHome);
                } else {
                  GetStore.getInstance().cleanUser();
                  final hint = user.expiresAtDisplay.isNotEmpty
                      ? '服务已到期（${user.expiresAtDisplay}），请充值后联系管理员续期'
                      : '服务已到期或未开通，请充值后联系管理员续期';
                  Get.snackbar(
                    '请充值',
                    hint,
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.orange.withValues(alpha: 0.9),
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                }
              } else {
                Get.snackbar(
                  '登录失败',
                  message,
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
              }
            },
            onModel: (m) => UserModel.fromJson(m));
      } catch (e) {
        // 处理异常
        Get.snackbar(
          '登录失败',
          '网络连接错误，请稍后重试',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } finally {
        // 重置加载状态
        state.isLoading.value = false;
      }
    }
  }
}
