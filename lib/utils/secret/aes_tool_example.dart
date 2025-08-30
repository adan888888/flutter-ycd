import  'package:encrypt/encrypt.dart' as encrypt;

void main() {
 /* //1.(字符串)将字符串转为key, 一定需要32个字符
  final keyStr = 'your 32 length key........';
  final key111 = encrypt.Key.fromUtf8(keyStr);
   print("你好 $key111");

  //2.(字节数组) 0到255，一个字节8位   8*32=255位
  final keyBytes = Uint8List.fromList([
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10,
    0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18,
    0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20
  ]);

  final keyUtf8 = utf8.decode(keyBytes);//解码
  print('测试：$keyBytes');*/
  // 定义密钥和IV（初始向量）
  // AES - 256需要256位密钥
  // IV长度取决于加密模式
  final key = encrypt.Key.fromUtf8('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');//将 UTF - 8 编码的字符串转换为密钥对象
  // final iv = encrypt.IV.fromLength(16); //默认的IV生成方式(每次都会变)
  final iv = encrypt.IV.fromUtf8("0123456789abcdef");


  // 创建加密器，这里使用AES加密，CBC模式和PKCS7填充
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));

  // 要加密的明文
  final plainText = '123456';

  // 加密
  final encrypted = encrypter.encrypt(plainText, iv: iv);

  // 解密
  // final decrypted = encrypter.decrypt(encrypted, iv: iv);
  final decrypted1 = encrypter.decrypt64(encrypted.base64, iv: iv);

  print('加密后: ${encrypted.base64}');
  print('解密后: $decrypted1');
}

