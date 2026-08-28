import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/utils/local_util.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/storage_util.dart';
import 'package:ycd/views/splash/splash_view.dart';

import 'routes/app_routes.dart'; // 导入新的路由配置文件

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 初始化存储器
  await StorageUtil.init();
  await GetStore.initStorageNamespace();
  //检查登录状态
  GetStore.getInstance().checkLoginStatus();
  //加载默认语言
  LocalUtil.loadDefaultLan();
  // 先解好启动图再起首帧，避免系统启动屏退场后先闪一下纯色背景
  await _precacheSplashImage();
  runApp(const MyApp());
}

Future<void> _precacheSplashImage() async {
  final completer = Completer<void>();
  final stream = const AssetImage(SplashView.imageAsset).resolve(ImageConfiguration.empty);
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
        locale: const Locale('zh', 'CN'),
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
