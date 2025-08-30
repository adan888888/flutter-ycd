import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../main.dart';
import '../../model/user_model.dart';
import '../../utils/network/Api.dart';
import '../../utils/network/get_store.dart';
import '../../utils/network/http_mgr.dart';
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
    if (formKey.currentState!.validate()) {
      // 设置加载状态
      state.isLoading.value = true;

      String email = emailController.text;
      String usrname = userNameController.text;
      String password = passwordController.text;

      try {
        // 真实登录逻辑
        BXPost<UserModel>(Api.login,
            params: {"username": usrname, "password": password},
            success: (isSuccess, code, message, results) {
              if (isSuccess) {
                GetStore.getInstance().saveUser(results.first);
                Future.delayed(const Duration(seconds: 2), () {
                  var userId = GetStore.getInstance().readUserModel().userId;
                  if (userId.isNotEmpty) {
                    Get.offAndToNamed(AppRoutes.home);
                  }
                });
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
