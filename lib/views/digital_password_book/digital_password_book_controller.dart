import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/http_mgr.dart';

import 'digital_password_book_state.dart';

class DigitalPasswordBookController extends GetxController {
  final state = DigitalPasswordBookState();
  final searchTextController = TextEditingController(); // 搜索输入框控制器
  final editTitleController = TextEditingController(); // 编辑标题控制器
  final editUsernameController = TextEditingController(); // 编辑用户名控制器
  final editPasswordController = TextEditingController(); // 编辑密码控制器
  final editWebsiteController = TextEditingController(); // 编辑网站控制器
  final editNotesController = TextEditingController(); // 编辑备注控制器

  @override
  void onInit() {
    super.onInit();
    loadPasswordList(); // 异步调用，不等待结果
  }

  @override
  void onClose() {
    searchTextController.dispose(); // 释放资源
    editTitleController.dispose();
    editUsernameController.dispose();
    editPasswordController.dispose();
    editWebsiteController.dispose();
    editNotesController.dispose();
    super.onClose();
  }

  // 加载密码列表
  void loadPasswordList({String? keyword, VoidCallback? onSuccess, Function(String)? onError}) {
    Map<String, dynamic>? params;
    if (keyword != null && keyword.isNotEmpty) {
      params = {'keyword': keyword};
    }

    BXGet<PasswordItem>(
      Api.passwordBookList,
      params: params,
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          state.passwordList.clear();
          state.passwordList.addAll(results);
          onSuccess?.call();
        } else {
          onError?.call(message);
        }
      },
      failed: (error, baseModel) {
        onError?.call(error);
      },
      onModel: (json) => PasswordItem.fromJson(json),
      isShowLoading: true,
      showError: true,
    );
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

    final passwordData = {
      'title': state.newTitle.value,
      'username': state.newUsername.value,
      'password': state.newPassword.value,
      'website': state.newWebsite.value,
      'notes': state.newNotes.value,
    };

    BXPost<PasswordItem>(
      Api.passwordBook,
      params: passwordData,
      success: (isSuccess, code, message, results) {
        if (isSuccess && results.isNotEmpty) {
          state.passwordList.insert(0, results.first);
          clearAddForm();
          state.showAddDialog.value = false;
          Get.snackbar('成功', '密码已添加');
        }
      },
      onModel: (json) => PasswordItem.fromJson(json),
      isShowLoading: true,
      showError: true,
    );
  }

  // 编辑密码
  void editPassword(PasswordItem item) {
    state.selectedItem.value = item;
    editTitleController.text = item.title;
    editUsernameController.text = item.username;
    editPasswordController.text = item.password;
    editWebsiteController.text = item.website;
    editNotesController.text = item.notes;
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

    final passwordData = {
      'title': state.editTitle.value,
      'username': state.editUsername.value,
      'password': state.editPassword.value,
      'website': state.editWebsite.value,
      'notes': state.editNotes.value,
    };

    BXPut<PasswordItem>(
      '${Api.passwordBookItem}/${selectedItem.id}',
      params: passwordData,
      success: (isSuccess, code, message, results) {
        if (isSuccess && results.isNotEmpty) {
          final updatedItem = results.first;
          final index = state.passwordList.indexWhere((item) => item.id == selectedItem.id);
          if (index != -1) {
            state.passwordList[index] = updatedItem;
            state.showEditDialog.value = false;
            Get.snackbar('成功', '密码已更新');
          }
        }
      },
      onModel: (json) => PasswordItem.fromJson(json),
      isShowLoading: true,
      showError: true,
    );
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
              BXDelete<dynamic>(
                '${Api.passwordBookItem}/${item.id}',
                success: (isSuccess, code, message, results) {
                  if (isSuccess) {
                    state.passwordList.removeWhere((e) => e.id == item.id);
                    Get.back();
                    Get.snackbar('成功', '密码已删除');
                  }
                },
                isShowLoading: true,
                showError: true,
              );
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

  // 一键复制标题、用户名、密码、网站
  void copyEntry(PasswordItem item) {
    final buffer = StringBuffer()
      ..writeln('标题：${item.title}')
      ..writeln('用户名：${item.username}')
      ..writeln('密码：${item.password}');
    if (item.website.isNotEmpty) {
      buffer.writeln('网站：${item.website}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trimRight()));
    Get.snackbar('成功', '账号信息已复制');
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
    return state.passwordList;
  }

  // 搜索密码
  void searchPasswords(String keyword) {
    state.searchKeyword.value = keyword;
    loadPasswordList(keyword: keyword.isEmpty ? null : keyword); // 异步调用，不等待结果
    _updateSearchPd(); // 更新搜索转换结果
  }

  // 清空搜索
  void clearSearch() {
    state.searchKeyword.value = '';
    searchTextController.clear(); // 清空输入框内容
    loadPasswordList(); // 重新加载所有密码
    _updateSearchPd(); // 更新搜索转换结果
  }

  // 切换匹配方向
  void toggleMatchDirection() {
    state.isReverseMatch.value = !state.isReverseMatch.value;
    _updateSearchPd(); // 更新搜索转换结果
  }

  // 更新搜索转换结果
  void _updateSearchPd() {
    if (state.searchKeyword.value.isEmpty) {
      state.searchPd.value = '';
      return;
    }

    final keyword = state.searchKeyword.value.toUpperCase();
    // 仅处理 A-Z，含其他字符则不做转换
    if (!_isAllLetters(keyword)) {
      state.searchPd.value = '';
      return;
    }

    if (state.isReverseMatch.value) {
      state.searchPd.value = _searchFromReverse(keyword);
    } else {
      state.searchPd.value = _searchFromForward(keyword);
    }
  }

  bool _isAllLetters(String keyword) {
    for (int i = 0; i < keyword.length; i++) {
      final code = keyword.codeUnitAt(i);
      if (code < 'A'.codeUnitAt(0) || code > 'Z'.codeUnitAt(0)) {
        return false;
      }
    }
    return true;
  }

  String _searchFromReverse(String keyword) {
    String result = '';

    for (int i = 0; i < keyword.length; i++) {
      final index = keyword.codeUnitAt(i) - 'A'.codeUnitAt(0);
      final mapped = state.randomSequence[index]; // 1-26
      result += String.fromCharCode('A'.codeUnitAt(0) + mapped - 1);
    }

    return result;
  }

  String _searchFromForward(String keyword) {
    String result = '';

    for (int i = 0; i < keyword.length; i++) {
      final target = keyword.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1; // 1-26
      final index = state.randomSequence.indexOf(target);
      if (index < 0) return '';
      result += String.fromCharCode('A'.codeUnitAt(0) + index);
    }

    return result;
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

  // 刷新密码列表
  void refreshPasswordList() {
    state.isLoading.value = true;

    // 重新加载密码列表，在回调中处理成功提示
    loadPasswordList(
      onSuccess: () {
        // 显示刷新成功提示
        Get.snackbar(
          '刷新成功',
          '密码列表已更新',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.refresh, color: Colors.white),
        );
        state.isLoading.value = false;
      },
      onError: (_) {
        state.isLoading.value = false;
      },
    );
  }

  // 设置当前选中的密码项
  void setCurrentSelectedItem(PasswordItem? item) {
    state.currentSelectedItem.value = item;
  }

  // 处理键盘快捷键
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // 处理 Delete 键删除
      if (event.logicalKey == LogicalKeyboardKey.delete) {
        final selectedItem = state.currentSelectedItem.value;
        if (selectedItem != null) {
          deletePassword(selectedItem);
        }
      }
      // 处理 Enter 键编辑
      else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final selectedItem = state.currentSelectedItem.value;
        if (selectedItem != null) {
          editPassword(selectedItem);
        }
      }
    }
  }
}
