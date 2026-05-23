import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';

import 'login_controller.dart';

class LoginWidget extends GetView<LoginController> {
  const LoginWidget({super.key});

  static const Color _gold = Color(0xFFD4B896);
  static const Color _goldDark = Color(0xFFC9A86C);
  static const Color _textLight = Color(0xFFE8E4DC);
  static const Color _textMuted = Color(0x99FFFFFF);
  static const Color _inputFill = Color(0xFF332F2D);
  static const double _loginButtonAspectRatio = 1020 / 150;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.12),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Obx(() {
                  final isLoginTab = c.state.authTabIndex.value == 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAuthTabs(c),
                      SizedBox(height: 28.h),
                      if (isLoginTab) ...[
                        Form(
                          key: c.formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInput(
                                controller: c.userNameController,
                                hint: '请输入邮箱/手机号/账号',
                                prefix: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '请输入账号';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12.h),
                              Obx(
                                () => _buildInput(
                                  controller: c.passwordController,
                                  hint: '请输入登录密码',
                                  prefix: Icons.lock_outline,
                                  obscureText: c.state.isPasswordVisible.value,
                                  suffix: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                                    splashRadius: 18.r,
                                    onPressed: c.togglePasswordVisibility,
                                    icon: Icon(
                                      c.state.isPasswordVisible.value
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _gold,
                                      size: 20.w,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return '请输入密码';
                                    if (value.length < 2) return '密码长度至少2位';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(height: 12.h),
                              _buildRememberRow(c),
                              SizedBox(height: 20.h),
                              Obx(() => _buildLoginButton(c)),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _buildSkipEntry(),
                        SizedBox(height: 20.h),
                        _buildServiceEntry(c),
                      ] else
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.h),
                          child: Text(
                            '请联系管理员开通账号',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: _textMuted,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Image.asset(
      'assets/images/login_bg.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/game_backgroud.jpg',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    );
  }

  Widget _buildAuthTabs(LoginController c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabItem(c, index: 0, label: '登录'),
        SizedBox(width: 48.w),
        _buildTabItem(c, index: 1, label: '注册'),
      ],
    );
  }

  Widget _buildTabItem(LoginController c, {required int index, required String label}) {
    return Obx(() {
      final selected = c.state.authTabIndex.value == index;
      return GestureDetector(
        onTap: () => c.state.authTabIndex.value = index,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18.sp,
                color: selected ? _textLight : _textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: 28.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: selected ? _goldDark : Colors.transparent,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRememberRow(LoginController c) {
    return Obx(
      () => Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4.r),
            onTap: () => c.state.autoLogin.value = !c.state.autoLogin.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 12.w),
                Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: c.state.autoLogin.value ? _gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(color: _gold.withValues(alpha: 0.8), width: 1.w),
                  ),
                  child: c.state.autoLogin.value ? Icon(Icons.check, color: const Color(0xFF2A2218), size: 12.w) : null,
                ),
                SizedBox(width: 6.w),
                Text(
                  '记住密码',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _textLight.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: c.showContactAdminTip,
            child: Text(
              '忘记密码?',
              style: TextStyle(
                fontSize: 13.sp,
                color: _textLight.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(LoginController c) {
    final loading = c.state.isLoading.value;
    return AspectRatio(
      aspectRatio: _loginButtonAspectRatio,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : c.login,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.asset(
                  'assets/images/login_button.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.fill,
                ),
              ),
              if (loading)
                SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D3428)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: 50.h,
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        style: TextStyle(
          color: _textLight,
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: _gold,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 12.sp),
          prefixIcon: Icon(prefix, color: _gold, size: 16.w),
          suffixIcon: suffix,
          filled: true,
          fillColor: _inputFill,
          contentPadding: EdgeInsets.only(left: 0, right: 10.w, top: 12.h, bottom: 12.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.15), width: 0.5.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.45), width: 1.w),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.w),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.w),
          ),
          errorStyle: TextStyle(fontSize: 12.sp, color: Colors.red.shade300),
        ),
      ),
    );
  }

  Widget _buildSkipEntry() {
    return GestureDetector(
      onTap: () => Get.offAllNamed(AppRoutes.home),
      child: Text(
        '跳过登录，先去逛逛',
        style: TextStyle(
          fontSize: 14.sp,
          color: _textLight.withValues(alpha: 0.75),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildServiceEntry(LoginController c) {
    return GestureDetector(
      onTap: c.showContactAdminTip,
      child: Text(
        '联系客服',
        style: TextStyle(
          fontSize: 16.sp,
          color: _goldDark,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
