import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt_package;

import 'aes_constants.dart';

/// AES加解密工具类
class AesTool {
  /// 验证密钥长度
  /// AES密钥必须是16、24或32字节（128、192或256位）
  static String? validateKey(String? key) {
    if (key == null || key.isEmpty) {
      return null; // 空值使用默认密钥，不需要验证
    }
    final keyBytes = key.codeUnits.length;
    if (keyBytes != 16 && keyBytes != 24 && keyBytes != 32) {
      return '密钥长度必须是16、24或32字节（当前: $keyBytes 字节）';
    }
    return null;
  }

  /// 验证IV长度
  /// AES IV必须是16字节（128位）
  static String? validateIv(String? iv) {
    if (iv == null || iv.isEmpty) {
      return null; // 空值使用默认IV，不需要验证
    }
    final ivBytes = iv.codeUnits.length;
    if (ivBytes != 16) {
      return 'IV长度必须是16字节（当前: $ivBytes 字节）';
    }
    return null;
  }

  /// 加密
  /// [plainText] 要加密的明文
  /// [key] 密钥，如果为空则使用默认密钥
  /// [iv] 初始化向量，如果为空则使用默认IV
  /// 返回加密后的Base64字符串
  static String encrypt(String plainText, {String? key, String? iv}) {
    try {
      // 使用传入的key或默认key
      final encryptKey = encrypt_package.Key.fromUtf8(key ?? AESCONSTANT.KEY);
      // 使用传入的iv或默认iv
      final encryptIv = encrypt_package.IV.fromUtf8(iv ?? AESCONSTANT.IV);

      // 创建加密器
      final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(encryptKey, mode: encrypt_package.AESMode.cbc, padding: 'PKCS7'),
      );

      // 加密
      final encrypted = encrypter.encrypt(plainText, iv: encryptIv);

      // 返回Base64格式的密文
      return encrypted.base64;
    } catch (e) {
      throw Exception('加密失败: $e');
    }
  }

  /// 将Base64字符串转换为16进制字符串
  static String base64ToHex(String base64) {
    try {
      final bytes = encrypt_package.Encrypted.fromBase64(base64).bytes;
      return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
    } catch (e) {
      throw Exception('Base64转16进制失败: $e');
    }
  }

  /// 判断字符串是否为16进制格式
  static bool isHexString(String str) {
    // 移除可能的空格和换行
    final cleaned = str.replaceAll(RegExp(r'[\s\n\r]'), '');
    // 检查是否只包含0-9和a-f（不区分大小写）
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned) && cleaned.length % 2 == 0;
  }

  /// 将16进制字符串转换为Base64字符串
  static String hexToBase64(String hex) {
    try {
      // 移除可能的空格和换行
      final cleaned = hex.replaceAll(RegExp(r'[\s\n\r]'), '');
      // 将16进制字符串转换为字节数组
      final bytes = Uint8List.fromList(
        List.generate(
          cleaned.length ~/ 2,
          (i) => int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );
      // 转换为Base64
      final encrypted = encrypt_package.Encrypted(bytes);
      return encrypted.base64;
    } catch (e) {
      throw Exception('16进制转Base64失败: $e');
    }
  }

  /// 解密
  /// [encryptedInput] Base64或16进制格式的密文（自动判断）
  /// [key] 密钥，如果为空则使用默认密钥
  /// [iv] 初始化向量，如果为空则使用默认IV
  /// 返回解密后的明文
  static String decrypt(String encryptedInput, {String? key, String? iv}) {
    try {
      // 使用传入的key或默认key
      final decryptKey = encrypt_package.Key.fromUtf8(key ?? AESCONSTANT.KEY);
      // 使用传入的iv或默认iv
      final decryptIv = encrypt_package.IV.fromUtf8(iv ?? AESCONSTANT.IV);

      // 创建解密器
      final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(decryptKey, mode: encrypt_package.AESMode.cbc, padding: 'PKCS7'),
      );

      // 自动判断输入格式：16进制还是Base64
      String base64Input;
      if (isHexString(encryptedInput)) {
        // 如果是16进制，先转换为Base64
        base64Input = hexToBase64(encryptedInput);
      } else {
        // 否则当作Base64处理
        base64Input = encryptedInput;
      }

      // 解密
      final decrypted = encrypter.decrypt64(base64Input, iv: decryptIv);

      return decrypted;
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }
}
