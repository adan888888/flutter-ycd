import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:ycd/utils/local_util.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/storage_util.dart';

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

  // 每个实例使用独立 Hive 路径，支持多开
  final baseDir = await getApplicationDocumentsDirectory();
  final hivePath = path.join(
    baseDir.path,
    'hive_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}',
  );
  Hive.init(hivePath);
  // 初始化存储器
  await StorageUtil.init();
  await GetStore.initStorageNamespace();
  //检查登录状态
  GetStore.getInstance().checkLoginStatus();
  //加载默认语言
  LocalUtil.loadDefaultLan();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      minTextAdapt: true,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primaryColor: Colors.green,
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.home,
        getPages: AppPages.pages,
        builder: EasyLoading.init(),
      ),
    );
  }
}
