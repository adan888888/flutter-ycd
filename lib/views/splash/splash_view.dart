import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';

/// 启动页：原生窗口背景（Android 的 launch_background / iOS 的 LaunchScreen）会先铺出同一张图，
/// 这里在 Flutter 首帧接着画，两段拼在一起看不出切换。缩放方式与两端原生保持一致（拉伸铺满）。
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  /// 与 launch_image 四周的纯色、Android windowSplashScreenBackground 保持一致
  static const Color backgroundColor = Color(0xFF1A9748);

  static const String imageAsset = 'assets/images/launch_image.jpg';

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const Duration _holdDuration = Duration(milliseconds: 600);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_holdDuration, () {
      // login 页带 AppMiddleware，已登录会自动重定向到首页
      Get.offAllNamed(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SplashView.backgroundColor,
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(SplashView.imageAsset),
          fit: BoxFit.fill,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
