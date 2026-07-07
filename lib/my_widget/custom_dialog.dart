import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_controller.dart';

/// 庄闲对话框
///
/// 显示庄或闲的对话框，500毫秒后自动关闭
class ZhuangXianDialog extends StatefulWidget {
  final String title;
  final Color? darkTextColor;

  const ZhuangXianDialog(
    this.title, {
    super.key,
    this.darkTextColor,
  });

  @override
  State<ZhuangXianDialog> createState() => _ZhuangXianDialogState();
}

class _ZhuangXianDialogState extends State<ZhuangXianDialog> {
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    timer ??= Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      Get.find<JiShuQiController>().guardAgainstKeyboardPop();
      Get.back();
    });
    final gameController = Get.find<JiShuQiController>();
    return Center(
      child: Text(
        widget.title,
        style: TextStyle(
          fontSize: 90,
          color: gameController.state.isDarkMode
              ? widget.darkTextColor ?? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
