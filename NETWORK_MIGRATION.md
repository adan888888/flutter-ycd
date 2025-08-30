# 网络请求从 GetConnect 迁移到 Dio

## 迁移概述

本项目已成功将网络请求库从 GetConnect 迁移到 Dio，提升了网络请求的性能、稳定性和可维护性。

## 主要改进

### 🚀 性能提升
- **更快的请求速度**: Dio 在底层使用更高效的 HTTP 客户端
- **更好的内存管理**: 减少了内存泄漏的风险
- **并发请求优化**: 更好的并发处理能力

### 🛡️ 稳定性增强
- **更完善的错误处理**: 详细的错误类型分类和处理
- **请求重试机制**: 支持自动重试失败的请求
- **超时控制**: 更精确的超时设置

### 🔧 开发体验
- **更清晰的日志**: 使用表情符号和结构化日志
- **更好的调试**: 详细的请求和响应信息
- **类型安全**: 更好的类型检查和错误提示

## 文件结构

```
lib/utils/network/
├── dio_manager.dart      # Dio 管理器（单例模式）
├── http_service.dart     # HTTP 服务层
├── http_mgr.dart         # 兼容层（保持原有API）
├── Api.dart             # API 接口定义
└── network_test.dart    # 网络测试工具
```

## 核心特性

### 1. 请求拦截器
- 自动添加认证头
- 设备信息注入
- 请求日志记录

### 2. 响应拦截器
- 统一错误处理
- 登录状态检查
- 响应数据解析

### 3. 错误处理
- 网络超时处理
- 服务器错误处理
- 证书错误处理

## 使用方式

### 原有代码无需修改
```dart
// 这些代码保持不变，底层已切换到Dio
BXPost<UserModel>(
  Api.login,
  params: {"username": "admin1", "password": "123"},
  success: (isSuccess, code, message, results) {
    // 处理成功响应
  },
  onModel: (json) => UserModel.fromJson(json),
);
```

### 新的直接使用方式
```dart
// 直接使用HttpService
HttpService.getInstance().post<UserModel>(
  Api.login,
  params: {"username": "admin1", "password": "123"},
  success: (isSuccess, code, message, results) {
    // 处理成功响应
  },
  onModel: (json) => UserModel.fromJson(json),
);
```

## 配置说明

### 超时设置
- 连接超时: 15秒
- 接收超时: 15秒
- 发送超时: 15秒

### 请求头
- Content-Type: application/json
- Authorization: Bearer token
- 设备信息: 自动注入
- 语言设置: 自动检测

## 测试

运行网络测试：
```dart
NetworkTest.testDioService();
```

## 依赖

```yaml
dependencies:
  dio: ^5.4.0
```

## 注意事项

1. **向后兼容**: 原有的 `BXPost`、`BXGet` 等函数保持不变
2. **错误处理**: 错误信息更加详细和用户友好
3. **日志输出**: 使用表情符号让日志更易读
4. **性能监控**: 可以轻松添加性能监控和统计

## 迁移完成

✅ 添加 Dio 依赖  
✅ 创建 DioManager  
✅ 创建 HttpService  
✅ 更新 http_mgr.dart  
✅ 保持 API 兼容性  
✅ 添加测试工具  
✅ 完善错误处理  
✅ 清理 GetConnect 相关代码  

## 清理工作

### 删除的文件
- `lib/utils/network/network.dart` - 旧的网络请求实现
- `lib/utils/network/BaseProvider.dart` - GetConnect 提供者

### 保留的文件
- `lib/utils/network/http_mgr.dart` - 兼容层（保持原有API）
- `lib/utils/network/dio_manager.dart` - Dio 管理器
- `lib/utils/network/http_service.dart` - HTTP 服务层
- `lib/utils/network/Api.dart` - API 接口定义

项目现在使用更现代、更强大的 Dio 网络库，同时保持了原有的使用方式，确保平滑迁移。所有 GetConnect 相关代码已完全清理。
