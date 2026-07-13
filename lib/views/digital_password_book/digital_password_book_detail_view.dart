import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'digital_password_book_controller.dart';
import 'digital_password_book_state.dart';

class DigitalPasswordBookDetailView extends GetView<DigitalPasswordBookController> {
  const DigitalPasswordBookDetailView({super.key});

  PasswordItem _resolveItem() {
    final initial = Get.arguments as PasswordItem;
    final index = controller.state.passwordList.indexWhere((entry) => entry.id == initial.id);
    if (index == -1) return initial;
    return controller.state.passwordList[index];
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final item = _resolveItem();

      return Scaffold(
        appBar: AppBar(
          title: Text(item.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: '复制全部',
              onPressed: () => controller.copyEntry(item),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑',
              onPressed: () => controller.editPassword(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: '删除',
              onPressed: () => controller.deletePassword(
                item,
                onDeleted: () => Get.back(),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailField(
                      icon: Icons.label_outline,
                      label: '标题',
                      value: item.title,
                      onCopy: () => controller.copyField(item.title, '标题'),
                    ),
                    _DetailField(
                      icon: Icons.person,
                      label: '用户名',
                      value: item.username,
                      onCopy: () => controller.copyUsername(item.username),
                    ),
                    _PasswordField(item: item),
                    if (item.website.isNotEmpty)
                      _DetailField(
                        icon: Icons.language,
                        label: '网站',
                        value: item.website,
                        onCopy: () => controller.copyField(item.website, '网站'),
                      ),
                    if (item.notes.isNotEmpty)
                      _DetailField(
                        icon: Icons.note,
                        label: '备注',
                        value: item.notes,
                        multiline: true,
                        onCopy: () => controller.copyField(item.notes, '备注'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailField(
                      icon: Icons.schedule,
                      label: '创建时间',
                      value: _formatTime(item.createdAt),
                    ),
                    _DetailField(
                      icon: Icons.update,
                      label: '更新时间',
                      value: _formatTime(item.updatedAt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: '复制$label',
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class _PasswordField extends GetView<DigitalPasswordBookController> {
  const _PasswordField({required this.item});

  final PasswordItem item;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isVisible = controller.state.showPassword[item.id] ?? false;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            SizedBox(
              width: 72,
              child: Text(
                '密码',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            Expanded(
              child: Text(
                isVisible ? item.password : '••••••••',
                style: const TextStyle(fontSize: 15),
              ),
            ),
            IconButton(
              icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 18),
              tooltip: isVisible ? '隐藏密码' : '显示密码',
              onPressed: () => controller.togglePasswordVisibility(item.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: '复制密码',
              onPressed: () => controller.copyPassword(item.password),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      );
    });
  }
}
