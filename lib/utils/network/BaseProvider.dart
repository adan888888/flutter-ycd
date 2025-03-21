import 'package:get/get.dart';

import 'Api.dart';

class BaseProvider extends GetConnect{
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    baseUrl = Api.baseUrl;
    timeout = const Duration(seconds: 15);
    httpClient.timeout = timeout;
    ///请求拦截
    httpClient.addRequestModifier<void>((request) {
      return request;
    });
    ///相应拦截
    httpClient.addResponseModifier((request, response) {
      return response;
    });

  }
}