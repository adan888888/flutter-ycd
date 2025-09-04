import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:ycd/utils/local_util.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/storage_util.dart';
import 'routes/app_routes.dart'; // 导入新的路由配置文件

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
        initialRoute: AppRoutes.home,
        getPages: AppPages.pages,
        builder: EasyLoading.init(),
      ),
    );
  }
}
