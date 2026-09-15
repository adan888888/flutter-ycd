import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ycd/utils/day_night_theme.dart';

void main() {
  test('day hours are light', () {
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 6)), false);
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 12)), false);
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 17, 59)), false);
  });

  test('night hours are dark', () {
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 18)), true);
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 23)), true);
    expect(DayNightTheme.isDarkPeriod(DateTime(2026, 9, 15, 5, 59)), true);
  });

  test('next boundary from afternoon', () {
    final now = DateTime(2026, 9, 15, 14, 30);
    expect(DayNightTheme.nextBoundaryAfter(now), DateTime(2026, 9, 15, 18));
  });

  test('next boundary from before dawn', () {
    final now = DateTime(2026, 9, 15, 3, 0);
    expect(DayNightTheme.nextBoundaryAfter(now), DateTime(2026, 9, 15, 6));
  });

  test('light page: dark Android icons, iOS statusBarBrightness light', () {
    final style = DayNightTheme.systemUiOverlayStyle(false);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.statusBarBrightness, Brightness.light);
  });

  test('dark page: light Android icons, iOS statusBarBrightness dark', () {
    final style = DayNightTheme.systemUiOverlayStyle(true);
    expect(style.statusBarIconBrightness, Brightness.light);
    expect(style.statusBarBrightness, Brightness.dark);
  });
}
