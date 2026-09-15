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
}
