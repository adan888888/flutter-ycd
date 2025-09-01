import '../../model/base_model.dart';
import 'http_service.dart';

// 使用新的Dio服务
BXGet<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().get<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXPost<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().post<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXDelete<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().delete<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}

BXPut<T>(String api,
    {Map<String, dynamic>? params,
    required Function(bool isSuccess, int code, String message, List<T> results) success,
    Function(String, BaseModel)? failed,
    onModel,
    bool isShowLoading = true,
    bool canCache = true,
    bool showError = true}) {
  HttpService.getInstance().put<T>(
    api,
    params: params,
    success: success,
    failed: failed,
    onModel: onModel,
    isShowLoading: isShowLoading,
    showError: showError,
  );
}
