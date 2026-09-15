import 'package:flutter/material.dart';

/// 今日目标进度条（浅蓝描边 + 紫罗兰填充，圆角胶囊）。
class DailyGoalProgressBar extends StatelessWidget {
  const DailyGoalProgressBar({
    super.key,
    required this.progress,
    this.height = 7,
    this.isDarkMode = false,
    this.edgeLabel,
    this.edgeLabelStyle,
  });

  final double progress;
  final double height;
  final bool isDarkMode;
  final String? edgeLabel;
  final TextStyle? edgeLabelStyle;

  static const _fill = Color(0xFF7B6CFF);
  static const _borderLight = Color(0xFF9EC5FF);
  static const _trackLight = Color(0xFFF3F8FF);
  static const _borderDark = Color(0xFF4A6FA5);
  static const _trackDark = Color(0xFF1A2433);

  static const _edgeGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final border = isDarkMode ? _borderDark : _borderLight;
    final track = isDarkMode ? _trackDark : _trackLight;
    final label = edgeLabel?.trim() ?? '';
    final showLabel = label.isNotEmpty && edgeLabelStyle != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final fillW = w * clamped;

        Widget bar = Container(
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

        if (!showLabel) return bar;

        final style = edgeLabelStyle!;
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final labelW = painter.width;
        final labelH = painter.height;
        // 标签左缘贴在填充末端右侧，避免进度很小时被裁到条外左侧
        final labelLeft = (fillW + _edgeGap).clamp(0.0, (w - labelW).clamp(0.0, w));

        return SizedBox(
          height: labelH > height ? labelH : height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Align(alignment: Alignment.centerLeft, child: bar),
              Positioned(
                left: labelLeft,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
