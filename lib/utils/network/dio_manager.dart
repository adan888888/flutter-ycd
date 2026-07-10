import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../model/user_model.dart';
import '../local_util.dart';
import 'api.dart';
import 'get_store.dart';

class DioManager {
  static const _refreshedTokenHeader = 'x-refreshed-token';

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
    // 统一按响应体 business code 处理，不因 HTTP 4xx/5xx 抛 DioException
    _dio.options.validateStatus = (status) => status != null && status < 600;

    log('API baseUrl: ${Api.baseUrl}');

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
        _applyRefreshedToken(response);
        handler.next(response);
      },
      onError: (error, handler) {
        // 用户可读错误与 Toast 由 HttpService 统一处理
        handler.next(error);
      },
    ));
  }

  void _applyRefreshedToken(Response response) {
    final newToken = response.headers.value(_refreshedTokenHeader);
    if (newToken == null || newToken.isEmpty) return;
    final store = GetStore.getInstance();
    if (!store.isLogin) return;
    final user = store.userModel;
    user.token = newToken;
    store.saveUser(user);
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
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  // POST 请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  // PUT 请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put(path, data: data, queryParameters: queryParameters, options: options);

  // DELETE 请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
}
