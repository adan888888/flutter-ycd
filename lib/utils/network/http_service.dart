import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../model/base_model.dart';
import '../../routes/app_routes.dart'; // 添加路由配置导入
import '../bx_loading.dart';
import 'dio_manager.dart';
import 'get_store.dart';

class HttpService {
  static HttpService? _instance;
  final DioManager _dioManager = DioManager.getInstance();

  HttpService._internal();

  static HttpService getInstance() {
    _instance ??= HttpService._internal();
    return _instance!;
  }

  // GET 请求
  Future<void> get<T>(
    String api, {
    Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    bool isShowLoading = true,
    bool showError = true,
  }) async {
    await _request<T>(
      api,
      method: 'GET',
      params: params,
      success: success,
      failed: failed,
      onModel: onModel,
      isShowLoading: isShowLoading,
      showError: showError,
    );
  }

  // POST 请求
  Future<void> post<T>(
    String api, {
    Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    bool isShowLoading = true,
    bool showError = true,
  }) async {
    await _request<T>(
      api,
      method: 'POST',
      params: params,
      success: success,
      failed: failed,
      onModel: onModel,
      isShowLoading: isShowLoading,
      showError: showError,
    );
  }

  // PUT 请求
  Future<void> put<T>(
    String api, {
    Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    bool isShowLoading = true,
    bool showError = true,
  }) async {
    await _request<T>(
      api,
      method: 'PUT',
      params: params,
      success: success,
      failed: failed,
      onModel: onModel,
      isShowLoading: isShowLoading,
      showError: showError,
    );
  }

  // DELETE 请求
  Future<void> delete<T>(
    String api, {
    Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    bool isShowLoading = true,
    bool showError = true,
  }) async {
    await _request<T>(
      api,
      method: 'DELETE',
      params: params,
      success: success,
      failed: failed,
      onModel: onModel,
      isShowLoading: isShowLoading,
      showError: showError,
    );
  }

  Future<void> _request<T>(
    String api, {
    required String method,
    Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    bool isShowLoading = true,
    bool showError = true,
  }) async {
    if (isShowLoading) {
      BXLoading.show();
    }

    try {
      dio.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _dioManager.get(api, queryParameters: params);
          break;
        case 'POST':
          response = await _dioManager.post(api, data: params);
          break;
        case 'PUT':
          response = await _dioManager.put(api, data: params);
          break;
        case 'DELETE':
          response = await _dioManager.delete(api, queryParameters: params);
          break;
        default:
          throw Exception('不支持的请求方法: $method');
      }

      log('🌐 请求URL: ${response.requestOptions.method} ${response.requestOptions.uri}');
      if (response.requestOptions.data != null) {
        log('📝 请求参数: ${response.requestOptions.data}');
      }
      log('✅ 响应数据: ${response.statusCode} ${jsonEncode(response.data)}');
      log('\n---------------------------------------------------------------------------------------------------------------------------------------');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          BaseModel model = BaseModel.fromJson(data);

          if (model.code == 0) {
            final dynamic d = model.data;
            final listResult = d is List ? List<dynamic>.from(d) : <dynamic>[];
            if (onModel == null) {
              success(true, model.code, model.msg, List<T>.from(listResult));
            } else {
              if (listResult.isEmpty) {
                success(true, model.code, "数据为空", <T>[]);
              } else {
                final values = <T>[];
                for (final element in listResult) {
                  values.add(onModel(element));
                }
                success(true, model.code, model.msg, values);
              }
            }
          } else if (model.code == 2202) {
            _handleYcdExpired(showError, failed, model);
          } else {
            if (model.code == 1) {
              if (showError) BXLoading.showToast(model.msg);
            } else {
              if (failed != null) failed(model.msg, model);
              if (model.code != 8 && showError) BXLoading.showToast(model.msg);
            }
          }
        }
      } else {
        String errorMsg = '请求失败: ${response.statusCode}';
        if (showError) BXLoading.showToast(errorMsg);
        if (failed != null) {
          failed(
              errorMsg,
              BaseModel.fromJson({
                "code": response.statusCode ?? -1,
                "msg": errorMsg,
              }));
        }
      }
    } on dio.DioException catch (e) {
      String errorMsg = _handleDioError(e);

      // 处理401未授权错误（token过期）
      if (e.response?.statusCode == 401) {
        log('🔐 401错误: ${e.response?.data}');
        if (e.response!.data.toString().contains("Access denied")) {
          BXLoading.showToast("连接不上数据库，Access denied");
          return;
        }
        // 尝试解析服务端返回的错误信息
        try {
          if (e.response?.data != null) {
            BaseModel errorModel = BaseModel.fromJson(e.response!.data);
            errorMsg = errorModel.msg;
            log('🔐 解析的错误信息: $errorMsg');
          }
        } catch (parseError) {
          errorMsg = '登录已过期，请重新登录';
          log('🔐 解析错误信息失败: $parseError');
        }

        // 清除本地用户信息
        GetStore.getInstance().cleanUser();

        // 显示提示
        if (showError) BXLoading.showToast(errorMsg);

        // 跳转到登录页面（避免重复跳转）
        Future.delayed(const Duration(seconds: 1), () {
          // 检查当前是否已经在登录页面
          if (Get.currentRoute != AppRoutes.login) {
            log('🔄 跳转到登录页面，当前路由: ${Get.currentRoute}');
            Get.offAndToNamed(AppRoutes.login);
          } else {
            log('ℹ️ 当前已在登录页面，无需跳转');
          }
        });

        return;
      }

      // Web平台特殊处理
      if (kIsWeb && e.type == dio.DioExceptionType.connectionError) {
        errorMsg = 'Web平台连接错误，请检查后端服务器CORS配置';
      }

      if (showError) BXLoading.showToast(errorMsg);
      if (failed != null) {
        failed(errorMsg, BaseModel.fromJson({"code": -1, "msg": errorMsg}));
      }
    } catch (e) {
      String errorMsg = '网络异常: ${e.toString()}';
      log('❌ 网络异常: $errorMsg');
      if (showError) BXLoading.showToast(errorMsg);
      if (failed != null) {
        failed(errorMsg, BaseModel.fromJson({"code": -1, "msg": errorMsg}));
      }
    } finally {
      if (isShowLoading) {
        BXLoading.dismiss();
      }
    }
  }

  void _handleYcdExpired(
    bool showError,
    Function(String, BaseModel)? failed,
    BaseModel model,
  ) {
    const msg = '服务已到期，请联系管理员';
    log('💳 2202: $msg');
    GetStore.getInstance().cleanUser();
    if (showError) BXLoading.showToast(msg);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
    if (failed != null) {
      failed(msg, model);
    }
  }

  String _handleDioError(dio.DioException error) {
    switch (error.type) {
      case dio.DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case dio.DioExceptionType.sendTimeout:
        return '发送超时，请重试';
      case dio.DioExceptionType.receiveTimeout:
        return '接收超时，请重试';
      case dio.DioExceptionType.badResponse:
        // 特殊处理401错误
        if (error.response?.statusCode == 401) {
          return '登录已过期，请重新登录';
        }
        return '服务器响应错误: ${error.response?.statusCode}';
      case dio.DioExceptionType.cancel:
        return '请求已取消';
      case dio.DioExceptionType.connectionError:
        // 断网或网络不可达的情况
        if (error.message?.contains('Network is unreachable') == true ||
            error.message?.contains('No address associated with hostname') == true) {
          return '网络不可达，请检查网络连接';
        }
        return '网络连接失败，请检查网络连接';
      case dio.DioExceptionType.badCertificate:
        return '证书验证失败';
      case dio.DioExceptionType.unknown:
        // 检查是否是网络相关错误
        if (error.message?.contains('SocketException') == true ||
            error.message?.contains('Failed host lookup') == true) {
          return '网络连接失败，请检查网络连接';
        }
        return '未知错误: ${error.message}';
    }
  }
}
