import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/app_bootstrap.dart';

typedef AppBootstrapCallback = Future<void> Function();
typedef FirstFrameReadyCallback = Future<void> Function();

/// 启动页：原生启动层（Android SplashActivity / iOS LaunchScreen）会先铺出同一张图，
/// 这里在 Flutter 首帧接着画，两段拼在一起看不出切换。缩放方式与两端原生保持一致（拉伸铺满）。
class SplashView extends StatefulWidget {
  const SplashView({
    super.key,
    this.bootstrap,
    this.firstFrameReady,
    this.onFinished,
    this.minimumDisplayDuration = const Duration(milliseconds: 600),
  });

  /// 与 launch_image 四周的纯色、Android windowSplashScreenBackground 保持一致
  static const Color backgroundColor = Color(0xFF1A9748);

  static const String imageAsset = 'assets/images/launch_image.jpg';

  static final Completer<void> _firstFrameVisible = Completer<void>();

  static Future<void> waitForFirstFrame() => _firstFrameVisible.future;

  /// main.dart 在已经放出完整启动图首帧后调用。
  static void markFirstFrameVisible() {
    if (!_firstFrameVisible.isCompleted) {
      _firstFrameVisible.complete();
    }
  }

  /// 仅在测试或嵌入场景覆盖；正式启动使用 [AppBootstrap.initialize]。
  final AppBootstrapCallback? bootstrap;

  /// 仅在测试或嵌入场景覆盖；正式启动等待完整启动图首帧真正显示。
  final FirstFrameReadyCallback? firstFrameReady;

  /// 仅在测试或嵌入场景覆盖；正式启动会进入登录路由并由中间件决定去向。
  final VoidCallback? onFinished;

  final Duration minimumDisplayDuration;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late final Future<void> _minimumDisplay;
  Object? _initializationError;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _minimumDisplay = _waitForMinimumDisplay();
    unawaited(_initializeAndNavigate());
  }

  Future<void> _initializeAndNavigate() async {
    try {
      await Future.wait<void>([
        (widget.bootstrap ?? AppBootstrap.initialize)(),
        _minimumDisplay,
      ]);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'app bootstrap',
          context: ErrorDescription('while initializing the application'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _initializationError = error;
        _isInitializing = false;
      });
      return;
    }

    if (!mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
      return;
    }

    // login 页带 AppMiddleware，已登录会自动重定向到首页。
    Get.offAllNamed(AppRoutes.login);
  }

  void _retry() {
    if (_isInitializing) return;
    setState(() {
      _initializationError = null;
      _isInitializing = true;
    });
    unawaited(_initializeAndNavigate());
  }

  Future<void> _waitForMinimumDisplay() async {
    await (widget.firstFrameReady ?? SplashView.waitForFirstFrame)();
    await Future<void>.delayed(widget.minimumDisplayDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashView.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage(SplashView.imageAsset),
            fit: BoxFit.fill,
            gaplessPlayback: true,
          ),
          if (_initializationError != null)
            SafeArea(
              child: Center(
                child: Card(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '初始化失败，请重试',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _retry,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
