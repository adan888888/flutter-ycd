import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

import 'color_util.dart';

enum ToastType {
  getX,
  easyLoading,
}

class BXLoading {
  static const int val = 2;
  static int _refCount = 0;

  /// 与计数器页 `state.isDarkMode` 同步，供抖音风 Loading 自动配色。
  static bool isDarkMode = true;

  static void syncTheme(bool dark) {
    isDarkMode = dark;
  }

  /// 多个请求/手动 show 叠加时只保留一层 Loading，全部 release 后才 dismiss。
  static void acquire(VoidCallback present) {
    if (_refCount == 0) {
      present();
    }
    _refCount++;
  }

  static show({
    String? s,
    String? content,
    bool douyinStyle = false,
  }) {
    configLoading();
    acquire(() {
      EasyLoading.show(
        indicator: _buildIndicator(douyinStyle),
        maskType: EasyLoadingMaskType.clear,
        status: content ?? s,
      );
    });
  }

  static Widget _buildIndicator(bool douyinStyle) {
    //抖音风双球
    if (douyinStyle) {
      return SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: LoadingAnimationWidget.flickr(
            // 浅底用深色球、深底用浅色球，保证对比度
            leftDotColor: isDarkMode ? Colors.white : const Color(0xFF1A1A3F),
            rightDotColor: const Color(0xFFEA3799),
            size: 35,
          ),
        ),
      );
    }
    //Lottie 方块旋转
    return Container(
      decoration: BoxDecoration(
        color: ColorUtil.color_0xff733547,
        borderRadius: BorderRadius.circular(15.w),
      ),
      width: 90,
      height: 90,
      child: Center(
        child: Lottie.asset(
          'assets/loading.json',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static dismiss() {
    if (_refCount <= 0) {
      EasyLoading.dismiss();
      return;
    }
    _refCount--;
    if (_refCount == 0) {
      EasyLoading.dismiss();
    }
  }

  /// 异常兜底：强制归零并关闭 Loading。
  static void reset() {
    _refCount = 0;
    EasyLoading.dismiss();
  }

  static showToast(
    String toast, {
    int? interval,
    ToastType toastType = ToastType.easyLoading,
  }) {
    if (toastType == ToastType.getX) {
      Get.snackbar(
        "温馨提示",
        toast,
        duration: Duration(seconds: interval ?? val),
        snackPosition: SnackPosition.TOP,
      );
    } else {
      toastConfig();
      EasyLoading.showToast(
        toast,
        duration: Duration(seconds: interval ?? val),
        toastPosition: EasyLoadingToastPosition.center,
      );
    }
  }

  static showError({
    required String toast,
    int? interval,
  }) {
    Get.snackbar(
      "发现错误",
      toast,
      maxWidth: Get.width * 0.9,
      colorText: Colors.white,
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      duration: const Duration(
        seconds: 2,
      ),
      animationDuration: const Duration(
        milliseconds: 500,
      ),
      snackPosition: SnackPosition.TOP,
    );
  }

  static configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(seconds: val)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = Colors.transparent
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..indicatorColor = Colors.white
      ..textColor = Colors.black
      ..maskColor = Colors.blue.withValues(alpha: 0.5)
      ..userInteractions = true
      ..dismissOnTap = false
      ..maskColor = Colors.transparent
      ..boxShadow = <BoxShadow>[];
  }

  static toastConfig() {
    EasyLoading.instance
      ..displayDuration = const Duration(seconds: val)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = ColorUtil.black.withValues(alpha: 0.5)
      ..indicatorSize = 45.0
      ..radius = 12
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..maskColor = Colors.blue.withValues(alpha: 0.5)
      ..userInteractions = true
      ..dismissOnTap = false;
  }
}
