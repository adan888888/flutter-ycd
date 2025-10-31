import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 庄闲对话框
///
/// 显示庄或闲的对话框，500毫秒后自动关闭
class ZhuangXianDialog extends StatefulWidget {
  final String title;

  const ZhuangXianDialog(
    this.title, {
    super.key,
  });

  @override
  State<ZhuangXianDialog> createState() => _ZhuangXianDialogState();
}

class _ZhuangXianDialogState extends State<ZhuangXianDialog> {
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    timer ??= Timer.periodic(const Duration(milliseconds: 500), (timer) => setState(() => Get.back()));
    return Center(
      child: Text(
        widget.title,
        style: const TextStyle(fontSize: 90),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

