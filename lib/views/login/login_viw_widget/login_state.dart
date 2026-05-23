import 'package:get/get.dart';

class LoginState {
  // 密码可见性状态
  final isPasswordVisible = true.obs;

  // 加载状态
  final isLoading = false.obs;

  // 记住密码：勾选后登录成功会保存账号密码，下次打开自动填入
  final autoLogin = true.obs;

  // 0=登录 1=注册
  final authTabIndex = 0.obs;

  LoginState() {
    ///Initialize variables
  }
}
