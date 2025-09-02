import 'package:flutter/material.dart';

class AutoText extends StatefulWidget {
  /// 要显示的文字
  final String text;

  ///指定text的父容器的宽度
  ///必须制定宽度
  final double width;

  ///最小的字体大小
  ///默认最小是6
  final double minTextSize;

  ///正常的字体大小
  ///默认值是14
  final double? textSize;

  /// 正常的字体大小
  /// 默认值是14
  final Color? textColor;

  /// 字体的样式
  final TextStyle? textStyle;

  AutoText({super.key, String? text, this.textStyle, required this.width, double? minTextSize, this.textColor, double? textSize})
      : minTextSize = minTextSize ?? 6,
        textSize = textSize ?? textStyle?.fontSize ?? 14,
        text = text ?? '';

  @override
  State<StatefulWidget> createState() {
    return AutoTextState();
  }
}

class AutoTextState extends State<AutoText> with TickerProviderStateMixin {
  final GlobalKey _autoTextKey = GlobalKey();

  // double _textWidth = 0.0;
  double _fontSize = 0;
  late final TextPainter textPainter;
  late final TextStyle textFieldTextStyle;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.textSize!;

    // 初始化文本样式
    textFieldTextStyle = widget.textStyle ?? TextStyle(fontSize: widget.textSize, color: widget.textColor);

    // 初始化文本绘制器
    textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: widget.text,
        style: textFieldTextStyle,
      ),
    );
    textPainter.layout();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
      ..addStatusListener((status) {
        double containerWidth = widget.width;
        if (status == AnimationStatus.completed) {
          //当前没有缩放前的text宽度

          var textWidth = textPainter.width;
          var fontSize = textFieldTextStyle.fontSize;

          /// only text width largger than Container Width can do while
          if (textWidth > containerWidth) {
            while (textWidth > containerWidth && fontSize! > widget.minTextSize) {
              fontSize -= 0.5;
              textPainter.text = TextSpan(
                text: widget.text,
                style: textFieldTextStyle.copyWith(fontSize: fontSize),
              );
              textPainter.layout();
              textWidth = textPainter.width;
            }
            setState(() {
              // _textWidth = textWidth;
              _fontSize = fontSize!;
            });
          }
        }
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
        ),
        child: Text(maxLines: 1, widget.text, key: _autoTextKey, style: textFieldTextStyle.copyWith(fontSize: _fontSize, overflow: TextOverflow.visible)));
  }
}
