import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 按本地时间区分白天（亮色）与夜间（暗色）。
class DayNightTheme {
  DayNightTheme._();

  /// 亮色时段起点（含）：默认 6:00
  static const int dayStartHour = 6;

  /// 暗色时段起点（含）：默认 18:00
  static const int nightStartHour = 18;

  /// [dayStartHour, nightStartHour) 为亮色，其余为暗色。
  static bool isDarkPeriod(DateTime moment) {
    final h = moment.hour;
    return h >= nightStartHour || h < dayStartHour;
  }

  /// 下一次亮/暗切换时刻（用于定时刷新，避免每分钟轮询）。
  static DateTime nextBoundaryAfter(DateTime moment) {
    final dayStart = DateTime(moment.year, moment.month, moment.day, dayStartHour);
    final nightStart = DateTime(moment.year, moment.month, moment.day, nightStartHour);
    if (isDarkPeriod(moment)) {
      if (moment.hour < dayStartHour) {
        return dayStart;
      }
      return dayStart.add(const Duration(days: 1));
    }
    return nightStart;
  }

  /// 透明状态栏 + 与页面亮/暗匹配的系统图标（时间、电量等）。
  ///
  /// Android 看 [statusBarIconBrightness]；iOS 看 [statusBarBrightness]（与 icon 字段独立，勿混用 preset 整包）。
  static SystemUiOverlayStyle systemUiOverlayStyle(bool isDarkMode) {
    final iconBrightness = isDarkMode ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      systemNavigationBarIconBrightness: iconBrightness,
      // 与 [SystemUiOverlayStyle.dark]/[.light] 一致：亮底 → light，暗底 → dark
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    );
  }

  static void applySystemUiOverlayStyle(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle(isDarkMode));
  }
}
