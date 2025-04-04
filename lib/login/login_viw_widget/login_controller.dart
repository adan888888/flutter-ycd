import 'package:flutter/cupertino.dart';
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

  Future<void> login() async {
    if (formKey.currentState!.validate()) {
      String email = emailController.text;
      String usrname = userNameController.text;
      String password = passwordController.text;

      // 模拟登录逻辑（这里可以调用API）
      BXPost<UserModel>(Api.login,
          // params: { "username": "admin1","password": "123"},
          params: {"username": usrname, "password": password},
          success: (isSuccess, code, message, results) {
            if (isSuccess) {
              // ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(content: Text("登录成功: $usrname")));
              GetStore.getInstance().saveUser(results.first);
              Future.delayed(const Duration(seconds: 2), () {
                var userId = GetStore.getInstance().readUserModel().userId;
                if (userId.isNotEmpty) {
                  Get.offAndToNamed(AppRoutes.home);
                }
              });
            }
          },
          onModel: (m) => UserModel.fromJson(m));
    }
  }
}
