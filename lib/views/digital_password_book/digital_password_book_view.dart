import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'digital_password_book_controller.dart';
import 'digital_password_book_state.dart';

class DigitalPasswordBookView extends GetView<DigitalPasswordBookController> {
  const DigitalPasswordBookView({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: controller.handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('数字密码本'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.refreshPasswordList,
              tooltip: '刷新密码列表',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: controller.showAddPasswordDialog,
              tooltip: '添加密码',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildPasswordList()),
                Obx(() => Text(controller.state.searchPd.value.toLowerCase())),
                const SizedBox(height: 20),
              ],
            ),
            const AddPasswordDialog(),
            const EditPasswordDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() => Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.searchTextController,
                  onChanged: (value) {
                    try {
                      controller.searchPasswords(value);
                    } catch (e) {
                      if (!e.toString().contains('HardwareKeyboard') && !e.toString().contains('KeyUpEvent')) {
                        rethrow;
                      }
                    }
                  },
                  decoration: InputDecoration(
                    hintText: '搜索密码...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.state.searchKeyword.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearSearch,
                            tooltip: '清空搜索',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: controller.state.isReverseMatch.value,
                onChanged: (_) => controller.toggleMatchDirection(),
              ),
            ],
          )),
    );
  }

  Widget _buildPasswordList() {
    return Obx(() {
      if (controller.state.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredList = controller.filteredPasswordList;

      if (filteredList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.state.searchKeyword.value.isEmpty ? '暂无密码记录' : '未找到匹配的密码',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (controller.state.searchKeyword.value.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '点击右上角 + 添加第一个密码',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) => _buildPasswordCard(filteredList[index]),
      );
    });
  }

  Widget _buildPasswordCard(PasswordItem item) {
    return Obx(() {
      final isSelected = controller.state.currentSelectedItem.value?.id == item.id;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 2,
        color: isSelected ? Colors.blue.withValues(alpha: 0.08) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.openPasswordDetail(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.username,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      if (item.website.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.website,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        controller.copyEntry(item);
                        break;
                      case 'edit':
                        controller.editPassword(item);
                        break;
                      case 'delete':
                        controller.deletePassword(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_all, size: 20),
                          SizedBox(width: 8),
                          Text('复制'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
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
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      );
    });
  }
}

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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) => controller.state.newTitle.value = value,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => controller.state.newUsername.value = value,
                decoration: const InputDecoration(
                  labelText: '用户名 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => controller.state.newPassword.value = value,
                decoration: const InputDecoration(
                  labelText: '密码 *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => controller.state.newWebsite.value = value,
                decoration: const InputDecoration(
                  labelText: '网站',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => controller.state.newNotes.value = value,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 24),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.editTitleController,
                onChanged: (value) => controller.state.editTitle.value = value,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.editUsernameController,
                onChanged: (value) => controller.state.editUsername.value = value,
                decoration: const InputDecoration(
                  labelText: '用户名 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.editPasswordController,
                onChanged: (value) => controller.state.editPassword.value = value,
                decoration: const InputDecoration(
                  labelText: '密码 *',
                  border: OutlineInputBorder(),
                ),
                obscureText: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.editWebsiteController,
                onChanged: (value) => controller.state.editWebsite.value = value,
                decoration: const InputDecoration(
                  labelText: '网站',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.editNotesController,
                onChanged: (value) => controller.state.editNotes.value = value,
                decoration: const InputDecoration(
                  labelText: '备注',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: 24),
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
