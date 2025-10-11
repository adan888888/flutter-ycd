import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/http_mgr.dart';

import 'digital_password_book_state.dart';

class DigitalPasswordBookController extends GetxController {
  final state = DigitalPasswordBookState();

  @override
  void onInit() {
    super.onInit();
    loadPasswordList(); // 异步调用，不等待结果
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
        debugPrint('API调用成功: isSuccess=$isSuccess, code=$code, message=$message');
        debugPrint('返回结果数量: ${results.length}');
        if (results.isNotEmpty) {
          debugPrint('第一个结果: ${results.first.toJson()}');
        }
        if (isSuccess) {
          state.passwordList.clear();
          state.passwordList.addAll(results);
          debugPrint('密码列表更新后长度: ${state.passwordList.length}');
          // 调用成功回调
          onSuccess?.call();
        } else {
          Get.snackbar('错误', '加载密码列表失败: $message');
          onError?.call(message);
        }
      },
      failed: (error, baseModel) {
        Get.snackbar('错误', '加载密码列表失败: $error');
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

          // 清空表单
          clearAddForm();
          state.showAddDialog.value = false;

          Get.snackbar('成功', '密码已添加');
        } else {
          Get.snackbar('错误', '添加密码失败: $message');
        }
      },
      failed: (error, baseModel) {
        Get.snackbar('错误', '添加密码失败: $error');
      },
      onModel: (json) => PasswordItem.fromJson(json),
      isShowLoading: true,
      showError: true,
    );
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
        } else {
          Get.snackbar('错误', '更新密码失败: $message');
        }
      },
      failed: (error, baseModel) {
        Get.snackbar('错误', '更新密码失败: $error');
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
                  } else {
                    Get.snackbar('错误', '删除失败: $message');
                  }
                },
                failed: (error, baseModel) {
                  Get.snackbar('错误', '删除密码失败: $error');
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
  }

  // 清空搜索
  void clearSearch() {
    state.searchKeyword.value = '';
    loadPasswordList(); // 重新加载所有密码
  }

  // 获取搜索相关的状态
  String get searchPd {
    if (state.searchKeyword.value.isEmpty) {
      return '';
    } else {
      final keyword = state.searchKeyword.value.toUpperCase();
      final keywordLength = keyword.length;

      // 如果输入长度超过序列长度，返回空字符串
      if (keywordLength > state.randomSequence2.length) {
        return '';
      }

      // 从前面往后匹配，构建结果字符串
      String result = '';
      for (int i = 0; i < keywordLength; i++) {
        final keywordChar = keyword[i];
        bool found = false;

        // 在整个序列中查找以当前字符开头的项
        for (int j = 0; j < state.randomSequence2.length; j++) {
          final sequenceItem = state.randomSequence2[j];
          if (sequenceItem.startsWith(keywordChar)) {
            // 取序列项的第二个字符作为结果
            result += sequenceItem[1];
            found = true;
            break;
          }
        }

        if (!found) {
          // 如果不匹配，返回空字符串
          return '';
        }
      }

      return result;
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

  // 刷新密码列表
  void refreshPasswordList() {
    debugPrint('开始刷新密码列表...');
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
      onError: (error) {
        debugPrint('刷新密码列表失败: $error');
        Get.snackbar(
          '刷新失败',
          '无法更新密码列表: $error',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
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
