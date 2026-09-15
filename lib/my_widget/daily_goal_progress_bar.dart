import 'package:flutter/material.dart';

/// 今日目标进度条（浅蓝描边 + 紫罗兰填充，圆角胶囊）。
class DailyGoalProgressBar extends StatelessWidget {
  const DailyGoalProgressBar({
    super.key,
    required this.progress,
    this.height = 7,
    this.isDarkMode = false,
  });

  final double progress;
  final double height;
  final bool isDarkMode;

  static const _fill = Color(0xFF7B6CFF);
  static const _borderLight = Color(0xFF9EC5FF);
  static const _trackLight = Color(0xFFF3F8FF);
  static const _borderDark = Color(0xFF4A6FA5);
  static const _trackDark = Color(0xFF1A2433);

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final border = isDarkMode ? _borderDark : _borderLight;
    final track = isDarkMode ? _trackDark : _trackLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final fillW = w * clamped;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: fillW,
              height: height,
              decoration: BoxDecoration(
                color: _fill,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        );
      },
    );
  }
}
