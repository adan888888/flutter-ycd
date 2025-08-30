import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_controller.dart';

class LoginWidget extends GetView<LoginController> {
  const LoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 60.h),

                  // Logo和标题区域
                  _buildHeader(),

                  SizedBox(height: 10.h),

                  // 登录表单
                  _buildLoginForm(controller),

                  SizedBox(height: 40.h),

                  // 登录按钮
                  _buildLoginButton(controller),

                  SizedBox(height: 300.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              children: [
                // Logo
                Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.casino,
                    size: 60.w,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 24.h),

                // 标题
                Text(
                  '百家乐模拟器',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),

                SizedBox(height: 8.h),

                // 副标题
                Text(
                  '体验真实的游戏乐趣',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm(LoginController controller) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  // 用户名输入框
                  _buildTextField(
                    controller: controller.userNameController,
                    labelText: '用户名',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  // 密码输入框
                  Obx(() => _buildTextField(
                        controller: controller.passwordController,
                        labelText: '密码',
                        prefixIcon: Icons.lock_outline,
                        obscureText: controller.state.isPasswordVisible.value,
                        //为true时 看不见的
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.state.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密码';
                          } else if (value.length < 2) {
                            return '密码长度至少2位';
                          }
                          return null;
                        },
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      cursorColor: Colors.orange,
      cursorHeight: 15.h,
      style: TextStyle(
        color: Colors.white,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 17.sp,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 22.w,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.blueAccent.withValues(alpha: 0.8),
            width: 2.2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 2.2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.13),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        errorStyle: TextStyle(
          color: Colors.red.shade400,
          fontSize: 13.sp,
        ),
        // 优化：增加hintStyle
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 15.sp,
        ),
      ),
    );
  }

  Widget _buildLoginButton(LoginController controller) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Obx(() => Container(
                  width: double.infinity,
                  height: 46.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: controller.state.isLoading.value ? null : controller.login,
                      child: Container(
                        alignment: Alignment.center,
                        child: controller.state.isLoading.value
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                '登 录',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                )),
          ),
        );
      },
    );
  }
}
