import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/secret/aes_constants.dart';
import 'package:ycd/utils/secret/aes_tool.dart';

class AesEncryptController extends GetxController {
  // 输入内容控制器
  final TextEditingController contentController = TextEditingController();

  // Key输入控制器
  final TextEditingController keyController = TextEditingController();

  // IV输入控制器（可选）
  final TextEditingController ivController = TextEditingController();

  // 结果
  final RxString result = ''.obs;
  final RxString resultHex = ''.obs; // 16进制格式的结果
  final RxBool isEncryptMode = true.obs; // true: 加密模式, false: 解密模式
  final RxString errorMessage = ''.obs;

  // 用于实时显示输入长度
  final RxInt keyLength = 0.obs;
  final RxInt ivLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听密钥输入变化
    keyController.addListener(() {
      keyLength.value = keyController.text.length;
    });
    // 监听IV输入变化
    ivController.addListener(() {
      ivLength.value = ivController.text.length;
    });
  }

  @override
  void onClose() {
    contentController.dispose();
    keyController.dispose();
    ivController.dispose();
    super.onClose();
  }

  /// 执行加密
  void performEncrypt() {
    try {
      errorMessage.value = '';

      if (contentController.text.isEmpty) {
        errorMessage.value = '请输入要加密的内容';
        return;
      }

      // 如果输入框为空，使用默认值；否则使用输入框的值
      final key = keyController.text.isEmpty ? AESCONSTANT.KEY : keyController.text;
      final iv = ivController.text.isEmpty ? AESCONSTANT.IV : ivController.text;

      // 验证密钥长度
      final keyError = AesTool.validateKey(keyController.text.isEmpty ? null : keyController.text);
      if (keyError != null) {
        errorMessage.value = keyError;
        return;
      }

      // 验证IV长度
      final ivError = AesTool.validateIv(ivController.text.isEmpty ? null : ivController.text);
      if (ivError != null) {
        errorMessage.value = ivError;
        return;
      }

      final encrypted = AesTool.encrypt(
        contentController.text,
        key: key,
        iv: iv,
      );

      result.value = encrypted;
      // 同时生成16进制格式
      resultHex.value = AesTool.base64ToHex(encrypted);
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
      result.value = '';
    }
  }

  /// 执行解密
  void performDecrypt() {
    try {
      errorMessage.value = '';

      if (contentController.text.isEmpty) {
        errorMessage.value = '请输入要解密的内容';
        return;
      }

      // 如果输入框为空，使用默认值；否则使用输入框的值
      final key = keyController.text.isEmpty ? AESCONSTANT.KEY : keyController.text;
      final iv = ivController.text.isEmpty ? AESCONSTANT.IV : ivController.text;

      // 验证密钥长度
      final keyError = AesTool.validateKey(keyController.text.isEmpty ? null : keyController.text);
      if (keyError != null) {
        errorMessage.value = keyError;
        return;
      }

      // 验证IV长度
      final ivError = AesTool.validateIv(ivController.text.isEmpty ? null : ivController.text);
      if (ivError != null) {
        errorMessage.value = ivError;
        return;
      }

      final decrypted = AesTool.decrypt(
        contentController.text,
        key: key,
        iv: iv,
      );

      result.value = decrypted;
      resultHex.value = ''; // 解密结果不需要16进制显示
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = e.toString();
      result.value = '';
    }
  }

  /// 切换加密/解密模式
  void toggleMode() {
    isEncryptMode.value = !isEncryptMode.value;
    result.value = '';
    resultHex.value = '';
    errorMessage.value = '';
  }

  /// 清空内容输入（保留密钥和IV）
  void clearAll() {
    contentController.clear();
    // 不清空 keyController 和 ivController，保留用户输入的密钥和IV
    result.value = '';
    resultHex.value = '';
    errorMessage.value = '';
  }

  /// 填充默认密钥（如果输入框为空）
  void fillDefaultKey() {
    if (keyController.text.isEmpty) {
      keyController.text = AESCONSTANT.KEY;
    }
  }

  /// 填充默认IV（如果输入框为空）
  void fillDefaultIv() {
    if (ivController.text.isEmpty) {
      ivController.text = AESCONSTANT.IV;
    }
  }
}

