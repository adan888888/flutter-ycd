import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/views/splash/splash_view.dart';

import 'routes/app_routes.dart'; // 导入新的路由配置文件

const appLocale = Locale('zh', 'CN');
const appSupportedLocales = <Locale>[
  appLocale,
  Locale('en', 'US'),
];
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // 添加全局错误处理，忽略键盘相关的已知错误
  FlutterError.onError = (FlutterErrorDetails details) {
    // 忽略硬件键盘相关的错误
    if (details.exception.toString().contains('HardwareKeyboard') ||
        details.exception.toString().contains('KeyUpEvent') ||
        details.exception.toString().contains('_pressedKeys.containsKey')) {
      // 这些是已知的 Flutter 框架问题，不影响应用功能
      return;
    }
    // 其他错误正常处理
    FlutterError.presentError(details);
  };

  // Android 让 Flutter 背景绘制到手势导航区域；页面内的 SafeArea 仍负责保护内容。
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Flutter 与启动图解码同时开始，只把“尚未解出完整启动图”的帧拦住。
  // 存储和登录初始化会在 SplashView 显示期间执行，不再延长 Android 系统启动屏。
  binding.deferFirstFrame();
  final splashImageReady = _precacheSplashImage();
  runApp(const MyApp());
  unawaited(_showSplashFirstFrame(binding, splashImageReady));
}

Future<void> _showSplashFirstFrame(
  WidgetsBinding binding,
  Future<void> splashImageReady,
) async {
  await splashImageReady;
  binding.allowFirstFrame();

  try {
    // 等完整启动图真正完成一帧后再开始计算它的最短展示时间。
    await binding.endOfFrame;
  } finally {
    SplashView.markFirstFrameVisible();
  }
}

Future<void> _precacheSplashImage() async {
  final completer = Completer<void>();
  final stream =
      const AssetImage(SplashView.imageAsset).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void done() {
    stream.removeListener(listener);
    if (!completer.isCompleted) completer.complete();
  }

  listener = ImageStreamListener((_, __) => done(), onError: (_, __) => done());
  stream.addListener(listener);
  return completer.future;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: '数策',
        theme: ThemeData(
          primaryColor: Colors.green,
          useMaterial3: true,
        ),
        locale: appLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        fallbackLocale: const Locale('en', 'US'),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        routingCallback: (routing) {
          // token 过期 / 主动退出等场景：进入登录页时强制清掉残留 Loading
          if (routing?.current == AppRoutes.login) {
            BXLoading.reset();
          }
        },
        builder: EasyLoading.init(),
      ),
    );
  }
}
