import 'package:encrypt/encrypt.dart';
import 'aes_constant.dart';

void main() {
  // 定义密钥
  final key = Key.fromUtf8(AESCONSTANT.KEY);
  // 定义IV（假设加密时使用了默认的IV生成方式，这里需要和加密时一致）
  final iv = IV.fromUtf8(AESCONSTANT.IV);
  // 创建解密器
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
  var plainText="123456";
  try {

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    print('加密后的内容: ${encrypted.base64}');
    print('加密后的内容: ${encrypted.base16}');
  } catch (e) {
    print('加密失败: $e');
  }
}