import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../../model/user_model.dart';
import '../local_util.dart';
import 'get_store.dart';
import 'Api.dart';

class DioManager {
  static DioManager? _instance;
  late Dio _dio;

  DioManager._internal() {
    _dio = Dio();
    _initDio();
  }

  static DioManager getInstance() {
    _instance ??= DioManager._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  void _initDio() {
    // 基础配置
    _dio.options.baseUrl = Api.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);

    // Web平台特殊配置
    if (kIsWeb) {
      // 移除可能冲突的头部
      _dio.options.headers.remove('Access-Control-Allow-Origin');
      _dio.options.headers.remove('Access-Control-Allow-Methods');
      _dio.options.headers.remove('Access-Control-Allow-Headers');

      // 设置更简单的配置
      _dio.options.headers['Content-Type'] = 'application/json';
    }

    // 请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 添加请求头
        final headers = await _getHeaders();
        options.headers.addAll(headers);
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        log('❌ 错误: ${error.message}');
        handler.next(error);
      },
    ));
  }

  Future<Map<String, String>> _getHeaders() async {
    Map<String, String> headers = {};

    GetStore.getInstance().checkLoginStatus();
    bool isLogin = GetStore.getInstance().isLogin;
    String token = '';
    String xUserId = '';

    if (isLogin) {
      UserModel userModel = GetStore.getInstance().userModel;
      token = userModel.token;

      //检查token是否已经包含Bearer前缀，如果有则移除
      if (token.startsWith('Bearer ')) {
        token = token.substring(7);
      }

      xUserId = userModel.userId.toString();
    }

    String deviceid = await GetStore.getInstance().getDeviceId();
    PackageInfo info = await PackageInfo.fromPlatform();
    String os = '';
    String xDeviceType = '';
    String lan = LocalUtil.getLoaclString();

    if (kIsWeb) {
      os = "WEB";
      xDeviceType = "4";
    } else if (Platform.isIOS) {
      os = "IOS";
      xDeviceType = "3";
    } else {
      os = "ANDROID";
      xDeviceType = "2";
    }

    headers = {
      "Content-type": "application/json;charset=UTF-8",
      "X-Device-Type": xDeviceType,
      "X-Device-Id": deviceid,
      "X-Lang": lan,
      "X-Platform-Id": "C",
      "X-App-Terminal-Id": os,
      "Authorization": "Bearer $token",
      "UserId": xUserId,
    };

    return headers;
  }

  // GET 请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        log('连接超时');
        break;
      case DioExceptionType.sendTimeout:
        log('发送超时');
        break;
      case DioExceptionType.receiveTimeout:
        log('接收超时');
        break;
      case DioExceptionType.badResponse:
        log('响应错误: ${error.response?.statusCode}');
        break;
      case DioExceptionType.cancel:
        log('请求被取消');
        break;
      case DioExceptionType.connectionError:
        log('连接错误');
        break;
      case DioExceptionType.unknown:
        log('未知错误: ${error.message}');
        break;
      case DioExceptionType.badCertificate:
        log('证书错误');
        break;
    }
  }
}
