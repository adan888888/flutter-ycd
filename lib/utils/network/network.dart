import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import '../../model/base_model.dart';
import '../bx_loading.dart';
import 'Api.dart';
import 'BaseProvider.dart';
import 'get_store.dart';
import 'http_mgr.dart';

enum NetSate {
  SUCCESS,
  FAIL,
  TokenExpired;

  int get CODE {
    switch (this) {
      case NetSate.SUCCESS:
        return 0;
      case NetSate.FAIL:
        return 1;
      case NetSate.TokenExpired:
        return 100005;
    }
  }
}

class Network {
  static Network? _singleton;
  int repeatCount = 0;

  Network._internal();

  static Network getInstance() {
    _singleton ??= Network._internal();
    provider ??= BaseProvider();
    return _singleton!;
  }

  static Network yNet() => Network.getInstance();

  static BaseProvider? provider;

  void get<T>(String api,
      {Map<String, dynamic>? params,
      required Function(bool isSuccess, int code, String message, List<T> results) success,
      Function(String, BaseModel)? failed,
      onModel,
      bool isShowLoading = true,
      bool canCache = true,
      bool showError = true}) {
    request<T>(api,
        method: HttpMethod.get,
        params: params,
        success: success,
        failed: failed,
        isShowLoading: isShowLoading,
        canCache: canCache,
        onModel: onModel,
        showError: showError);
  }

  void post<T>(String api,
      {Map<String, dynamic>? params,
      required Function(bool isSuccess, int code, String message, List<T> results) success,
      Function(String, BaseModel)? failed,
      onModel,
      bool isShowLoading = true,
      bool canCache = true,
      bool showError = true}) {
    request<T>(
      api,
      method: HttpMethod.post,
      params: params,
      success: success,
      failed: failed,
      isShowLoading: isShowLoading,
      canCache: canCache,
      onModel: onModel,
      showError: showError,
    );
  }

  void put<T>(String api,
      {Map<String, dynamic>? params,
      required Function(bool isSuccess, int code, String message, List<T> results) success,
      Function(String, BaseModel)? failed,
      onModel,
      bool isShowLoading = true,
      bool canCache = true,
      bool showError = true}) {
    request<T>(api,
        method: HttpMethod.put,
        params: params,
        success: success,
        failed: failed,
        isShowLoading: isShowLoading,
        canCache: canCache,
        onModel: onModel,
        showError: showError);
  }

  void delete<T>(String api,
      {Map<String, dynamic>? params,
      required Function(bool isSuccess, int code, String message, List<T> results) success,
      Function(String, BaseModel)? failed,
      onModel,
      bool isShowLoading = true,
      bool canCache = true,
      bool showError = true}) {
    request<T>(api,
        method: HttpMethod.delete,
        params: params,
        success: success,
        failed: failed,
        isShowLoading: isShowLoading,
        canCache: canCache,
        onModel: onModel,
        showError: showError);
  }

  void request<T>(String api,
      {HttpMethod method = HttpMethod.get,
      Map<String, dynamic>? params,
      required Function(bool isSuccess, int code, String message, List<T> results) success,
      Function(String, BaseModel)? failed,
      Function(dynamic, int)? errorResult,
      onModel,
      bool isShowLoading = true,
      bool canCache = true,
      bool showError = true}) async {
    if (isShowLoading) {
      BXLoading.show();
    }

    Response? response;
    String url = getBaseUrl() + api;
    log("*****url=$url*****参数***${jsonEncode(params ?? {})}");
    try {
      if (method == HttpMethod.get) {
        if (params != null && params.isNotEmpty) {
          url += "?";
          int i = 0;
          params.forEach((key, value) {
            if (i < params.length - 1) {
              url += "$key=$value&";
            } else {
              url += "$key=$value";
            }
            i++;
          });
        }
        Map<String, String>? header = await getAppHeader();
        response = await provider?.get(url, headers: header);
      } else if (method == HttpMethod.post) {
        Map<String, String>? header = await getAppHeader();
        response = await provider?.post(url, jsonEncode(params ?? {}), headers: header);
      } else if (method == HttpMethod.put) {
        Map<String, String>? header = await getAppHeader();
        response = await provider?.put(url, jsonEncode(params ?? {}), headers: header);
      } else if (method == HttpMethod.delete) {
        if (params != null && params.isNotEmpty) {
          url += "?";
          int i = 0;
          params.forEach((key, value) {
            if (i < params.length - 1) {
              url += "$key=$value&";
            } else {
              url += "$key=$value";
            }
            i++;
          });
        }
        Map<String, String>? header = await getAppHeader();
        response = await provider?.delete(url, headers: header);
      }
      log("===${response?.bodyString}");
      if (response?.statusCode != null && response?.statusCode == 200) {
        if (response != null && (response?.bodyString ?? "").isNotEmpty) {
          var data = jsonDecode(response!.bodyString!);
          BaseModel model = BaseModel.fromJson(data);
          if (model.code == 0) {
            // log("${model.data}");
            var result = model.data ?? [];
            if (onModel == null) {
              success!(true, model.code, "", result);
            } else {
              List<T> values = [];
              if ((result as List).isEmpty) {
                success!(true, model.code, "数据为空", []);
              } else {
                for (var element in result) {
                  values.add(onModel(element));
                }
                success!(true, model.code, "", values);
              }
            }
            if (isShowLoading) {
              BXLoading.dismiss();
            }
          } else {
            if (model.code == 1) {
              if (showError) BXLoading.showToast(model.msg);
              if (errorResult != null) errorResult(model.data, model.code);
            } else {
              if (failed != null) failed!(model.msg, model);
              if (model.code != 8 && showError) BXLoading.showToast(model.msg);
            }
            if (model.data != null && model.code == 7 && ((model.data as List).first["reload"] ?? false)) {
              if (!GetStore.getInstance().isLogout) {
                GetStore.getInstance().isLogout = true;
                loginout();
              }
            }
          }
          if (isShowLoading) {
            BXLoading.dismiss();
          }
        }
      } else {
        if (response?.statusText != null && response!.statusText!.contains("timed out")) {
          log("***********数据异常***********${response?.statusText} ${response?.statusCode}}");
          if (showError) BXLoading.showToast("网络繁忙 ${response?.statusText} ${response?.statusCode}");
        } else {
          if (showError) BXLoading.showToast("${response?.statusText} ${response?.statusCode}");
        }
        // if (failed != null) failed!("网络异常", BaseModel.fromJson({"code": -1}));
      }
    } catch (e) {
      log("***********数据异常***********${e.toString()}");
      if (showError) BXLoading.showToast("网络异常 ${e.toString()}");
      if (failed != null) failed!("网络异常", BaseModel.fromJson({"code": -1}));
      if (isShowLoading) {
        BXLoading.dismiss();
      }
    }
  }

  String getBaseUrl() {
    return Api.baseUrl;
  }
}
