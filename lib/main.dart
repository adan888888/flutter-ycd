import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:ycd/my_home/my_home_binding.dart';
import 'package:ycd/utils/local_util.dart';
import 'my_home/my_home_view.dart';

void main() {
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
        initialRoute: AppPages.home,
        getPages: AppPages.pages,
        builder: EasyLoading.init(),
      ),
    );
  }
}

class AppPages {
  static const String home = '/home';
  static final pages = [GetPage(name: home, page: () => const MyHomePage(title: '记牌器 v1.0'), binding: MyHomeBinding())];
}
