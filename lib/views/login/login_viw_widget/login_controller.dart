import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/model/user_model.dart';
import 'package:ycd/my_widget/review_approved_dialog.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/network/http_mgr.dart';
import 'package:ycd/utils/storage_util.dart';

import 'login_state.dart';

class LoginController extends GetxController {
  static const String _keyAutoLogin = 'login_auto_login';
  static const String _keySavedUsername = 'login_saved_username';
  static const String _keySavedPassword = 'login_saved_password';

  final LoginState state = LoginState();

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController registerUsernameController =
      TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController registerPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  @override
  void onClose() {
    userNameController.dispose();
    registerUsernameController.dispose();
    nicknameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    registerPasswordController.dispose();
    confirmPasswordController.dispose();
    emailController.dispose();
    super.onClose();
  }

  void _loadSavedCredentials() {
    final autoLogin = StorageUtil.getBool(_keyAutoLogin) ?? false;
    state.autoLogin.value = autoLogin;
    if (!autoLogin) return;

    final username = StorageUtil.getString(_keySavedUsername);
    final password = StorageUtil.getString(_keySavedPassword);
    if (username != null && username.isNotEmpty) {
      userNameController.text = username;
    }
    if (password != null && password.isNotEmpty) {
      passwordController.text = password;
    }
  }

  Future<void> _persistLoginCredentials(
      String username, String password) async {
    if (state.autoLogin.value) {
      await StorageUtil.saveBool(_keyAutoLogin, true);
      await StorageUtil.saveString(_keySavedUsername, username);
      await StorageUtil.saveString(_keySavedPassword, password);
    } else {
      await StorageUtil.saveBool(_keyAutoLogin, false);
      await StorageUtil.remove(_keySavedUsername);
      await StorageUtil.remove(_keySavedPassword);
    }
  }

  // 切换密码可见性
  void togglePasswordVisibility() {
    state.isPasswordVisible.value = !state.isPasswordVisible.value;
  }

  void showContactAdminTip() {
    _showNotice(
      title: '联系客服',
      message: '如需帮助，请联系管理员处理',
      badgeText: '我们会妥善保护您的账户信息',
      icon: Icons.support_agent_rounded,
    );
  }

  void registerNotAvailable() {
    if (!formKey.currentState!.validate()) return;

    _showNotice(
      title: '暂未开放',
      message: '注册功能正在准备中，请稍后再试',
      badgeText: '感谢您的耐心等待',
      icon: Icons.schedule_rounded,
    );
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
            failed: (msg, _) {
              if (msg.isEmpty) return;
              _showNotice(
                title: '登录失败',
                message: msg,
                badgeText: '请检查账号信息后重新尝试',
                useFailureArtwork: true,
              );
            },
            success: (isSuccess, code, message, results) {
              if (!isSuccess || results.isEmpty) return;
              final user = results.first;
              GetStore.getInstance().saveUser(user);
              if (user.userId.isEmpty) return;
              _persistLoginCredentials(usrname, password);
              Get.offAndToNamed(AppRoutes.home);
            },
            onModel: (m) => UserModel.fromJson(m));
      } catch (e) {
        // 处理异常
        _showNotice(
          title: '登录失败',
          message: '网络连接错误，请稍后重试',
          badgeText: '请检查网络连接',
          useFailureArtwork: true,
        );
      } finally {
        // 重置加载状态
        state.isLoading.value = false;
      }
    }
  }

  void _showNotice({
    required String title,
    required String message,
    required String badgeText,
    IconData? icon,
    bool useFailureArtwork = false,
  }) {
    if (Get.isDialogOpen ?? false) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Get.dialog<void>(
      ReviewApprovedDialog(
        title: title,
        message: message,
        badgeText: badgeText,
        statusIcon: useFailureArtwork ? null : icon,
        useFailureArtwork: useFailureArtwork,
      ),
      barrierColor: Colors.black.withValues(alpha: 0.50),
    );
  }
}
