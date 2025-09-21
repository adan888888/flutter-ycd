import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'digital_password_book_controller.dart';

class DigitalPasswordBookView extends GetView<DigitalPasswordBookController> {
  const DigitalPasswordBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数字密码本'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: controller.showAddPasswordDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 搜索框
              _buildSearchBar(),
              // 密码列表
              Expanded(
                child: Obx(() => _buildPasswordList()),
              ),
              Obx(() => Text(controller.searchPd)),
              const SizedBox(height: 20),
            ],
          ),
          // 添加密码对话框
          const AddPasswordDialog(),
          // 编辑密码对话框
          const EditPasswordDialog(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showAddPasswordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          try {
            controller.state.searchKeyword.value = value;
          } catch (e) {
            // 忽略键盘相关的错误
            if (!e.toString().contains('HardwareKeyboard') && !e.toString().contains('KeyUpEvent')) {
              rethrow;
            }
          }
        },
        decoration: InputDecoration(
          hintText: '搜索密码...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // 构建密码列表
  Widget _buildPasswordList() {
    final filteredList = controller.filteredPasswordList;

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              controller.state.searchKeyword.value.isEmpty ? '暂无密码记录' : '未找到匹配的密码',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (controller.state.searchKeyword.value.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '点击右下角按钮添加第一个密码',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildPasswordCard(item);
      },
    );
  }

  // 构建密码卡片
  Widget _buildPasswordCard(item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => controller.editPassword(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          controller.editPassword(item);
                          break;
                        case 'delete':
                          controller.deletePassword(item);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 用户名
              _buildInfoRow(
                icon: Icons.person,
                label: '用户名',
                value: item.username,
                onCopy: () => controller.copyUsername(item.username),
              ),

              // 密码
              _buildPasswordRow(item),

              // 网站
              if (item.website.isNotEmpty)
                _buildInfoRow(
                  icon: Icons.language,
                  label: '网站',
                  value: item.website,
                ),

              // 备注
              if (item.notes.isNotEmpty)
                _buildInfoRow(
                  icon: Icons.note,
                  label: '备注',
                  value: item.notes,
                ),

              // 时间信息
              const SizedBox(height: 8),
              Text(
                '创建于: ${_formatDateTime(item.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  // 构建密码行
  Widget _buildPasswordRow(item) {
    return Obx(() {
      final isVisible = controller.state.showPassword[item.id] ?? false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.lock, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              '密码: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Expanded(
              child: Text(
                isVisible ? item.password : '••••••••',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                size: 16,
              ),
              onPressed: () => controller.togglePasswordVisibility(item.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () => controller.copyPassword(item.password),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    });
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// 添加密码对话框
class AddPasswordDialog extends GetView<DigitalPasswordBookController> {
  const AddPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.state.showAddDialog.value) return const SizedBox.shrink();

      return Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '添加新密码',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 标题
              TextField(
                onChanged: (value) => controller.state.newTitle.value = value,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 用户名
              TextField(
                onChanged: (value) => controller.state.newUsername.value = value,
                decoration: const InputDecoration(
                  labelText: '用户名 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 密码
              TextField(
                onChanged: (value) => controller.state.newPassword.value = value,
                decoration: const InputDecoration(
                  labelText: '密码 *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // 网站
              TextField(
                onChanged: (value) => controller.state.newWebsite.value = value,
                decoration: const InputDecoration(
                  labelText: '网站',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 备注
              TextField(
                onChanged: (value) => controller.state.newNotes.value = value,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.hideAddPasswordDialog,
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.addPassword,
                    child: const Text('添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// 编辑密码对话框
class EditPasswordDialog extends GetView<DigitalPasswordBookController> {
  const EditPasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.state.showEditDialog.value) return const SizedBox.shrink();

      return Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '编辑密码',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 标题
              TextField(
                controller: TextEditingController(text: controller.state.editTitle.value),
                onChanged: (value) => controller.state.editTitle.value = value,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 用户名
              TextField(
                controller: TextEditingController(text: controller.state.editUsername.value),
                onChanged: (value) => controller.state.editUsername.value = value,
                decoration: const InputDecoration(
                  labelText: '用户名 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 密码
              TextField(
                controller: TextEditingController(text: controller.state.editPassword.value),
                onChanged: (value) => controller.state.editPassword.value = value,
                decoration: const InputDecoration(
                  labelText: '密码 *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // 网站
              TextField(
                controller: TextEditingController(text: controller.state.editWebsite.value),
                onChanged: (value) => controller.state.editWebsite.value = value,
                decoration: const InputDecoration(
                  labelText: '网站',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 备注
              TextField(
                controller: TextEditingController(text: controller.state.editNotes.value),
                onChanged: (value) => controller.state.editNotes.value = value,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: controller.hideEditPasswordDialog,
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.updatePassword,
                    child: const Text('更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
