import 'package:encrypt/encrypt.dart';
import 'aes_constants.dart';

void main() {
  // 定义密钥
  final key = Key.fromUtf8(AESCONSTANT.KEY);
  // 定义IV（假设加密时使用了默认的IV生成方式，这里需要和加密时一致）
  final iv = IV.fromUtf8(AESCONSTANT.IV);
  // 创建解密器
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
  // 密文
  final encryptedBase64 = 'ZHpPjn8bOx/ujPt1+uJmMg==';
  try {
    // 解密
    final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);
    print('解密后的内容: $decrypted');
  } catch (e) {
    print('解密失败: $e');
  }
}
