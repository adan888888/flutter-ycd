import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/utils/log.dart';

/// Shorebird 热更新：启动后检查并下载补丁，下载完成后提示用户重启生效。
///
/// shorebird.yaml 里 auto_update 为 false，补丁只在这里下载。
abstract final class ShorebirdUpdate {
  static final _updater = ShorebirdUpdater();
  static const _restartChannel = MethodChannel('ycd/app_restart');
  static bool _checking = false;

  static Future<void> checkOnLaunch() async {
    if (_checking || !_updater.isAvailable) return;
    _checking = true;
    try {
      var status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _updater.update();
        status = UpdateStatus.restartRequired;
      }
      if (status == UpdateStatus.restartRequired) {
        await _showRestartDialog();
      }
    } on UpdateException catch (e) {
      Log.w('Shorebird 补丁更新失败: ${e.message}');
    } catch (e) {
      Log.w('Shorebird 检查更新失败: $e');
    } finally {
      _checking = false;
    }
  }

  /// 用户从版本菜单主动检查更新。与启动检查不同，无更新或失败时也会给出反馈。
  static Future<void> checkManually() async {
    if (!_updater.isAvailable) {
      await _showMessage('无法检查更新', '当前运行环境不支持 Shorebird 更新。');
      return;
    }
    if (_checking) {
      await _showMessage('正在检查更新', '请稍候再试。');
      return;
    }

    _checking = true;
    try {
      var status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        await _updater.update();
        status = UpdateStatus.restartRequired;
      }

      if (status == UpdateStatus.restartRequired) {
        await _showRestartDialog();
      } else {
        BXLoading.showToast('已是最新版本');
      }
    } on UpdateException catch (e) {
      Log.w('Shorebird 手动更新失败: ${e.message}');
      await _showMessage('检查更新失败', e.message);
    } catch (e) {
      Log.w('Shorebird 手动检查更新失败: $e');
      await _showMessage('检查更新失败', '请检查网络后重试。');
    } finally {
      _checking = false;
    }
  }

  static Future<void> _showMessage(String title, String content) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showRestartDialog() async {
    // 启动页结束时会 offAll 跳转，期间弹出的对话框会被一起移除。
    while (Get.context == null || Get.currentRoute == AppRoutes.splash) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    // 路由刚离开启动页时再等一帧，避免紧随其后的 offAll 移除对话框。
    await WidgetsBinding.instance.endOfFrame;
    if (Get.context == null || Get.currentRoute == AppRoutes.splash) {
      return _showRestartDialog();
    }

    final requiresManualRestart = Platform.isIOS;
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('发现新版本'),
        content: Text(
          requiresManualRestart
              ? '更新已下载完成。受 iOS 系统限制，应用不能自动重启。'
                  '请从应用切换器中彻底关闭本应用，再手动重新打开。'
              : '更新已下载完成，需要重启后才会生效。',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('稍后'),
          ),
          TextButton(
            onPressed: requiresManualRestart ? () => Get.back() : _restart,
            child: Text(requiresManualRestart ? '请手动重新打开' : '立即重启'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _restart() async {
    // iOS 不允许应用程序化退出或自启动；对话框只提供手动重启指引。
    if (Platform.isMacOS || Platform.isAndroid) {
      try {
        await _restartChannel.invokeMethod<void>('restart');
        return;
      } catch (e) {
        Log.w('原生重启不可用，请用户手动重新打开: $e');
        await _showMessage('无法自动重启', '请彻底关闭应用后手动重新打开。');
        return;
      }
    }
  }
}
