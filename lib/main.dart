import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:ycd/login/login_viw_widget/login_binding.dart';
import 'package:ycd/my_home/my_home_binding.dart';
import 'package:ycd/utils/app_middleware.dart';
import 'package:ycd/utils/local_util.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/storage_util.dart';
import 'login/login_viw_widget/login_view.dart';
import 'my_home/my_home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 Hive Flutter
  await Hive.initFlutter();
  //初始化存储器
  await StorageUtil.init();
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
        initialRoute: AppRoutes.login,
        getPages: AppPages.pages,
        builder: EasyLoading.init(),
      ),
    );
  }
}

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => LoginWidget(),
      binding: LoginBinding(),
      middlewares: [
        AppMiddleware(),
      ],
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MyHomePage(title: '记牌器 v1.0'),
      binding: MyHomeBinding(),
    )
  ];
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
}
