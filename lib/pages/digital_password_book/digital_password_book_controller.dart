import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/storage_util.dart';

import 'digital_password_book_state.dart';

class DigitalPasswordBookController extends GetxController {
  final state = DigitalPasswordBookState();

  @override
  void onInit() {
    super.onInit();
    loadPasswordList();
  }

  // 加载密码列表
  void loadPasswordList() {
    try {
      final savedPasswords = StorageUtil.getStringList('digital_password_book') ?? [];
      state.passwordList.clear();

      for (final passwordJson in savedPasswords) {
        try {
          // 解析JSON字符串
          final Map<String, dynamic> jsonData = jsonDecode(passwordJson);
          final passwordItem = PasswordItem.fromJson(jsonData);
          state.passwordList.add(passwordItem);
        } catch (e) {
          debugPrint('解析密码项失败: $e');
        }
      }

      // 按更新时间倒序排列
      state.passwordList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('加载密码列表失败: $e');
    }
  }

  // 保存密码列表
  void savePasswordList() {
    try {
      final passwordJsonList = state.passwordList.map((item) => jsonEncode(item.toJson())).toList();
      StorageUtil.saveStringList('digital_password_book', passwordJsonList);
    } catch (e) {
      debugPrint('保存密码列表失败: $e');
    }
  }

  // 添加新密码
  void addPassword() {
    if (state.newTitle.value.isEmpty) {
      Get.snackbar('提示', '请输入标题');
      return;
    }

    if (state.newUsername.value.isEmpty) {
      Get.snackbar('提示', '请输入用户名');
      return;
    }

    if (state.newPassword.value.isEmpty) {
      Get.snackbar('提示', '请输入密码');
      return;
    }

    final newId =
        state.passwordList.isEmpty ? 1 : state.passwordList.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;

    final newPasswordItem = PasswordItem(
      id: newId,
      title: state.newTitle.value,
      username: state.newUsername.value,
      password: state.newPassword.value,
      website: state.newWebsite.value,
      notes: state.newNotes.value,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state.passwordList.insert(0, newPasswordItem);
    savePasswordList();

    // 清空表单
    clearAddForm();
    state.showAddDialog.value = false;

    Get.snackbar('成功', '密码已添加');
  }

  // 编辑密码
  void editPassword(PasswordItem item) {
    state.selectedItem.value = item;
    state.editTitle.value = item.title;
    state.editUsername.value = item.username;
    state.editPassword.value = item.password;
    state.editWebsite.value = item.website;
    state.editNotes.value = item.notes;
    state.showEditDialog.value = true;
  }

  // 更新密码
  void updatePassword() {
    final selectedItem = state.selectedItem.value;
    if (selectedItem == null) return;

    if (state.editTitle.value.isEmpty) {
      Get.snackbar('提示', '请输入标题');
      return;
    }

    if (state.editUsername.value.isEmpty) {
      Get.snackbar('提示', '请输入用户名');
      return;
    }

    if (state.editPassword.value.isEmpty) {
      Get.snackbar('提示', '请输入密码');
      return;
    }

    final updatedItem = selectedItem.copyWith(
      title: state.editTitle.value,
      username: state.editUsername.value,
      password: state.editPassword.value,
      website: state.editWebsite.value,
      notes: state.editNotes.value,
      updatedAt: DateTime.now(),
    );

    final index = state.passwordList.indexWhere((item) => item.id == selectedItem.id);
    if (index != -1) {
      state.passwordList[index] = updatedItem;
      savePasswordList();
      state.showEditDialog.value = false;
      Get.snackbar('成功', '密码已更新');
    }
  }

  // 删除密码
  void deletePassword(PasswordItem item) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${item.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              state.passwordList.removeWhere((e) => e.id == item.id);
              savePasswordList();
              Get.back();
              Get.snackbar('成功', '密码已删除');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 复制密码到剪贴板
  void copyPassword(String password) {
    Clipboard.setData(ClipboardData(text: password));
    Get.snackbar('成功', '密码已复制到剪贴板');
  }

  // 复制用户名到剪贴板
  void copyUsername(String username) {
    Clipboard.setData(ClipboardData(text: username));
    Get.snackbar('成功', '用户名已复制到剪贴板');
  }

  // 切换密码显示状态
  void togglePasswordVisibility(int id) {
    state.showPassword[id] = !(state.showPassword[id] ?? false);
  }

  // 清空添加表单
  void clearAddForm() {
    state.newTitle.value = '';
    state.newUsername.value = '';
    state.newPassword.value = '';
    state.newWebsite.value = '';
    state.newNotes.value = '';
  }

  // 清空编辑表单
  void clearEditForm() {
    state.editTitle.value = '';
    state.editUsername.value = '';
    state.editPassword.value = '';
    state.editWebsite.value = '';
    state.editNotes.value = '';
    state.selectedItem.value = null;
  }

  // 获取过滤后的密码列表
  List<PasswordItem> get filteredPasswordList {
    if (state.searchKeyword.value.isEmpty) {
      return state.passwordList;
    }

    ///getter 的优势就是让 GetX 能够自动追踪依赖关系！
    // 这里 state.passwordList 是普通 List，不是 RxList，所以它本身的变化不会自动通知界面刷新。
    // 但 filteredPasswordList 是 get 的属性（getter），而界面用 Obx 包裹了 _buildPasswordList()，
    // searchKeyword 虽然是 .obs，但在 _buildPasswordList 里只是作为过滤条件参与判断，
    // 实际上 filteredPasswordList getter 依赖了 searchKeyword.value，
    // 所以每当 searchKeyword 变化时，Obx 包裹的 _buildPasswordList() 会自动刷新。
    return state.passwordList.where((item) {
      final keyword = state.searchKeyword.value.toLowerCase();
      return item.title.toLowerCase().contains(keyword) ||
          item.username.toLowerCase().contains(keyword) ||
          item.website.toLowerCase().contains(keyword) ||
          item.notes.toLowerCase().contains(keyword);
    }).toList();
  }

  // 获取搜索相关的状态
  String get searchPd {
    if (state.searchKeyword.value.isEmpty) {
      return '';
    } else {
      // 这里原来的写法是用where过滤后直接取first，如果没有匹配会抛异常
      // 改为firstWhere，并加上orElse返回空字符串，避免没有匹配时报错
      return state.randomSequence2.firstWhere(
        (element) => element.endsWith(state.searchKeyword.value.toUpperCase()),
        orElse: () => '',
      );
    }
  }

  // 显示添加密码对话框
  void showAddPasswordDialog() {
    clearAddForm();
    state.showAddDialog.value = true;
  }

  // 隐藏添加密码对话框
  void hideAddPasswordDialog() {
    state.showAddDialog.value = false;
    clearAddForm();
  }

  // 隐藏编辑密码对话框
  void hideEditPasswordDialog() {
    state.showEditDialog.value = false;
    clearEditForm();
  }
}
