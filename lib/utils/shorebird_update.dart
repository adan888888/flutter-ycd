import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/log.dart';

/// Shorebird 热更新：启动后检查并下载补丁，下载完成后提示用户重启生效。
///
/// shorebird.yaml 里 auto_update 为 false，补丁只在这里下载。
abstract final class ShorebirdUpdate {
  static final _updater = ShorebirdUpdater();
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

  static Future<void> _showRestartDialog() async {
    // 启动页结束时会 offAll 跳转，期间弹出的对话框会被一起移除。
    while (Get.context == null || Get.currentRoute == AppRoutes.splash) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await Get.dialog<void>(
      AlertDialog(
        title: const Text('发现新版本'),
        content: const Text('更新已下载完成，重启应用后生效。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('稍后'),
          ),
          TextButton(
            onPressed: () => exit(0),
            child: const Text('立即退出'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
