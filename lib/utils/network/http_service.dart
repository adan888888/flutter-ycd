import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';

import '../../model/base_model.dart';
import '../bx_loading.dart';
import 'dio_manager.dart';

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

      log('🌐 请求URL: ${response.requestOptions.uri}');
      log('📝 响应数据: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          BaseModel model = BaseModel.fromJson(data);

          if (model.code == 0) {
            var result = model.data ?? [];
            if (onModel == null) {
              success(true, model.code, model.msg, result);
            } else {
              List<T> values = [];
              if ((result as List).isEmpty) {
                success(true, model.code, "数据为空", []);
              } else {
                for (var element in result) {
                  values.add(onModel(element));
                }
                success(true, model.code, model.msg, values);
              }
            }
          } else {
            if (model.code == 1) {
              if (showError) BXLoading.showToast(model.msg);
            } else {
              if (failed != null) failed(model.msg, model);
              if (model.code != 8 && showError) BXLoading.showToast(model.msg);
            }

            // 处理登录失效
            if (model.data != null && model.code == 7 && ((model.data as List).first["reload"] ?? false)) {
              // 这里可以添加登录失效处理逻辑
              log('登录失效，需要重新登录');
            }
          }
        }
      } else {
        String errorMsg = '请求失败: ${response.statusCode}';
        if (showError) BXLoading.showToast(errorMsg);
        if (failed != null) failed(errorMsg, BaseModel.fromJson({"code": response.statusCode ?? -1, "msg": errorMsg}));
      }
    } on dio.DioException catch (e) {
      String errorMsg = _handleDioError(e);

      // Web平台特殊处理
      if (kIsWeb && e.type == dio.DioExceptionType.connectionError) {
        errorMsg = 'Web平台连接错误，请检查后端服务器CORS配置';
      }

      if (showError) BXLoading.showToast(errorMsg.contains("401") ? "用户名或者密码错误" : errorMsg);
      if (failed != null) failed(errorMsg, BaseModel.fromJson({"code": -1, "msg": errorMsg}));
    } catch (e) {
      String errorMsg = '网络异常: ${e.toString()}';
      log('❌ 网络异常: $errorMsg');
      if (showError) BXLoading.showToast(errorMsg);
      if (failed != null) failed(errorMsg, BaseModel.fromJson({"code": -1, "msg": errorMsg}));
    } finally {
      if (isShowLoading) {
        BXLoading.dismiss();
      }
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
        return '服务器响应错误: ${error.response?.statusCode}';
      case dio.DioExceptionType.cancel:
        return '请求已取消';
      case dio.DioExceptionType.connectionError:
        return '网络连接错误，请检查网络';
      case dio.DioExceptionType.badCertificate:
        return '证书验证失败';
      case dio.DioExceptionType.unknown:
        return '未知错误: ${error.message}';
    }
  }
}
