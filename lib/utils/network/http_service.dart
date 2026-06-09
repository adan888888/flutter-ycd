import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';

import '../../model/base_model.dart';
import '../bx_loading.dart';
import 'api_code.dart';
import 'api_session_handler.dart';
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

  /// 请求失败统一出口：日志、Toast、failed 回调。
  /// 业务层只需在 [failed] 里处理 UI 状态（如刷新头、按钮解禁），勿重复弹 Toast。
  void _failRequest<T>({
    required String errorMsg,
    required bool showError,
    Function(String, BaseModel)? failed,
  }) {
    log('❌ $errorMsg');
    if (showError && errorMsg.isNotEmpty) {
      BXLoading.showToast(errorMsg);
    }
    failed?.call(errorMsg, BaseModel.fromJson({"code": -1, "msg": errorMsg}));
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
      log('✅ 响应数据: ${jsonEncode(response.data)}');
      log('\n---------------------------------------------------------------------------------------------------------------------------------------');

      // Gin 路由不存在时 HTTP 404 + 纯文本，无 {code,msg,data}
      if (response.statusCode == 404) {
        final path = response.requestOptions.uri.path;
        _failRequest<T>(
          errorMsg: '接口不存在(404): $path',
          showError: showError,
          failed: failed,
        );
        return;
      }

      final model = _parseModel(response.data);
      if (model != null) {
        // 标准响应 { code, msg, data }：按业务码分发（成功 / 全局码 / 普通失败）
        if (_dispatchByBusinessCode(
          api,
          model,
          success: success,
          failed: failed,
          onModel: onModel,
          showError: showError,
        )) {
          return;
        }
      } else if (response.data != null) {
        // 非标准格式但有 msg/error 字段：兜底 Toast + failed
        final errorMsg = _backendMsg(response.data);
        if (errorMsg != null) {
          _failRequest<T>(
            errorMsg: errorMsg,
            showError: showError,
            failed: failed,
          );
        }
        return;
      }
    } on dio.DioException catch (e) /* Dio 传输层失败时进入（连不上、超时、断网、CORS、证书等）。 */ {
      final model = _parseModel(e.response?.data);
      if (model != null &&
          _dispatchByBusinessCode(
            api,
            model,
            success: success,
            failed: failed,
            onModel: onModel,
            showError: showError,
          )) {
        return;
      }

      final backendMsg = _backendMsg(e.response?.data);
      if (backendMsg != null) {
        _failRequest<T>(
          errorMsg: backendMsg,
          showError: showError,
          failed: failed,
        );
        return;
      }

      var errorMsg = _handleDioError(e);
      if (kIsWeb && e.type == dio.DioExceptionType.connectionError) {
        errorMsg = 'Web平台连接错误，请检查后端服务器CORS配置';
      }

      _failRequest<T>(
        errorMsg: errorMsg,
        showError: showError,
        failed: failed,
      );
    } catch (e) {
      _failRequest<T>(
        errorMsg: '网络异常: ${e.toString()}',
        showError: showError,
        failed: failed,
      );
    } finally {
      if (isShowLoading) {
        BXLoading.dismiss();
      }
    }
  }

  BaseModel? _parseModel(dynamic data) {
    if (data == null) return null;
    try {
      if (data is Map<String, dynamic>) {
        return BaseModel.fromJson(data);
      }
      if (data is Map) {
        return BaseModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      log('解析响应失败: $e');
    }
    return null;
  }

  bool _dispatchByBusinessCode<T>(
    String api,
    BaseModel model, {
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    Function(dynamic)? onModel,
    required bool showError,
  }) {
    if (ApiCodePolicy.isSuccess(model.code)) {
      final dynamic d = model.data;
      final listResult = d is List ? List<dynamic>.from(d) : <dynamic>[];
      if (onModel == null) {
        success(true, model.code, model.msg, List<T>.from(listResult));
      } else {
        if (listResult.isEmpty) {
          success(true, model.code, model.msg, <T>[]);
        } else {
          final values = <T>[];
          for (final element in listResult) {
            values.add(onModel(element));
          }
          success(true, model.code, model.msg, values);
        }
      }
      return true;
    }

    final isAuthApi = _isAuthApi(api);

    if (ApiCodePolicy.isGlobal(model.code)) {
      ApiSessionHandler.handleGlobal(
        model.code,
        model.msg,
        showError: showError,
        isAuthApi: isAuthApi,
      );
      return true;
    }

    ApiSessionHandler.handleBusinessFail(
      model,
      showError: showError,
      failed: failed,
      autoToast: ApiCodePolicy.shouldAutoToast(model.code, isAuthApi: isAuthApi),
    );
    return true;
  }

  bool _isAuthApi(String api) {
    return api.contains('/auth/login') || api.contains('/auth/register');
  }

  String? _backendMsg(dynamic data) {
    if (data == null) return null;
    final model = _parseModel(data);
    if (model != null && model.msg.isNotEmpty) return model.msg;
    if (data is Map) {
      final msg = data['msg'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      final error = data['error'];
      if (error != null && error.toString().isNotEmpty) return error.toString();
    }
    return null;
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
        return _backendMsg(error.response?.data) ?? '服务器响应错误';
      case dio.DioExceptionType.cancel:
        return '请求已取消';
      case dio.DioExceptionType.connectionError:
        // 断网、Connection refused、主机不可达等
        if (error.message?.contains('Network is unreachable') == true ||
            error.message?.contains('No address associated with hostname') == true) {
          return '网络不可达，请检查网络连接';
        }
        if (error.message?.contains('Connection refused') == true) {
          return '网络连接失败，请检查网络连接';
        }
        return '网络连接失败，请检查网络连接';
      case dio.DioExceptionType.badCertificate:
        return '证书验证失败';
      case dio.DioExceptionType.unknown:
        final msg = error.message ?? '';
        if (msg.contains('SocketException') ||
            msg.contains('Failed host lookup') ||
            msg.contains('Connection refused')) {
          return '网络连接失败，请检查网络连接';
        }
        return '未知错误: ${error.message}';
    }
  }
}
