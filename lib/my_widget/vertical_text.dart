import 'package:flutter/material.dart';

class VerticalText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const VerticalText(this.text, {this.style, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) => Text(char, style: style)).toList(),
    );
  }
}
