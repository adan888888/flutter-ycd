import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';

import 'login_controller.dart';

class LoginWidget extends GetView<LoginController> {
  const LoginWidget({super.key});

  static const Color _pageBg = Color(0xFFD3E1EF);
  static const Color _inputFill = Color(0xFFE6EBF2);
  static const Color _textPrimary = Color(0xFF3A4352);
  static const Color _textSecondary = Color(0xFF5B667A);
  static const Color _hint = Color(0xFF8E97A8);
  static const Color _icon = Color(0xFF8D96A7);
  static const Color _accent = Color(0xFF597EE8);
  static const Color _loginBtnStart = Color(0xFF4D6ED5);
  static const Color _loginBtnEnd = Color(0xFF2545AC);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 4.h, right: 12.w),
                child: _buildCloseButton(),
              ),
            ),
          ),
          Positioned(
            top: 100.h,
            left: 0,
            right: 0,
            child: _buildBrandLogo(128.w),
          ),
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoginCard(c),
                  SizedBox(height: 16.h),
                  _buildServiceEntry(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Align(
      alignment: Alignment.topCenter,
      child: Image.asset(
        'assets/images/login_bg.png',
        width: 1.sw,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/game_backgroud.jpg',
          width: 1.sw,
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _buildBrandLogo(double size) {
    return Center(
      child: Image.asset(
        'assets/images/ng_poker.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () {
        if (Get.key.currentState?.canPop() ?? false) {
          Get.back();
        }
      },
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          color: const Color(0xFF7C8BA1),
          size: 18.w,
        ),
      ),
    );
  }

  Widget _buildLoginCard(LoginController c) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F3A4F).withValues(alpha: 0.08),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Form(
        key: c.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput(
              controller: c.userNameController,
              hint: '请输入账号',
              prefix: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return '请输入用户名';
                return null;
              },
            ),
            SizedBox(height: 10.h),
            Obx(
              () => _buildInput(
                controller: c.passwordController,
                hint: '请输入密码',
                prefix: Icons.lock_outline,
                obscureText: c.state.isPasswordVisible.value,
                suffix: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                  splashRadius: 18.r,
                  onPressed: c.togglePasswordVisibility,
                  icon: Icon(
                    c.state.isPasswordVisible.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _icon,
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
            SizedBox(height: 6.h),
            Obx(
              () => Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () => c.state.autoLogin.value = !c.state.autoLogin.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18.w,
                          height: 18.w,
                          decoration: BoxDecoration(
                            color: c.state.autoLogin.value ? _accent : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.state.autoLogin.value ? _accent : _icon,
                              width: 1.5.w,
                            ),
                          ),
                          child: c.state.autoLogin.value ? Icon(Icons.check, color: Colors.white, size: 12.w) : null,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '自动登录',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '忘记密码',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() => _buildGradientLoginButton(c)),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: _buildTextAction(
                    '先去逛逛',
                    isPrimary: false,
                    onTap: () => Get.offAllNamed(AppRoutes.home),
                  ),
                ),
                Expanded(
                  child: _buildTextAction(
                    '注册账号',
                    isPrimary: true,
                    onTap: c.showContactAdminTip,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientLoginButton(LoginController c) {
    final loading = c.state.isLoading.value;
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: const LinearGradient(
            colors: [_loginBtnStart, _loginBtnEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : c.login,
            borderRadius: BorderRadius.circular(12.r),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
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
      height: 44.h,
      child: TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscureText,
        style: TextStyle(
          color: _textPrimary,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(color: _hint, fontSize: 15.sp),
          prefixIcon: Icon(prefix, color: _icon, size: 20.w),
          suffixIcon: suffix,
          filled: true,
          fillColor: _inputFill,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.6), width: 1.w),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.w),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.w),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAction(String text, {required bool isPrimary, VoidCallback? onTap}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: isPrimary ? _accent : _textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildServiceEntry() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.support_agent_outlined, color: _textSecondary, size: 20.w),
        SizedBox(width: 6.w),
        Text(
          '联系我们',
          style: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xFF2F3A4F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
