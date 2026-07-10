import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ycd/utils/secret/aes_constants.dart';

import 'aes_encrypt_controller.dart';

class AesEncryptView extends GetView<AesEncryptController> {
  const AesEncryptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AES加解密工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 模式切换
            _buildModeSwitch(),
            const SizedBox(height: 10),

            // 内容输入框
            _buildContentInput(),
            const SizedBox(height: 10),

            // Key输入框
            _buildKeyInput(),
            const SizedBox(height: 10),

            // IV输入框（可选）
            _buildIvInput(),
            const SizedBox(height: 10),

            // 操作按钮
            _buildActionButtons(),
            const SizedBox(height: 10),

            // 结果显示
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // 模式切换
  Widget _buildModeSwitch() {
    return Obx(() => Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  controller.isEncryptMode.value ? '加密模式' : '解密模式',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: controller.isEncryptMode.value,
                  onChanged: (_) => controller.toggleMode(),
                ),
              ],
            ),
          ),
        ));
  }

  // 内容输入框
  Widget _buildContentInput() {
    return Obx(() => Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.isEncryptMode.value ? '输入要加密的内容' : '输入要解密的内容（Base64/16进制）',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: controller.isEncryptMode.value ? '请输入要加密的明文' : '请输入Base64或16进制格式的密文',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  // Key输入框
  Widget _buildKeyInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '密钥（可选，留空使用默认）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller.keyController,
              onTap: () => controller.fillDefaultKey(),
              decoration: InputDecoration(
                hintText: '留空则使用默认密钥: ${AESCONSTANT.KEY}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 4),
            Obx(() => Text(
                  '当前长度: ${controller.keyLength.value} 字节（需要: 16/24/32 字节）',
                  style: TextStyle(
                    fontSize: 11,
                    color: controller.keyLength.value == 0
                        ? Colors.grey[500]
                        : (controller.keyLength.value == 16 ||
                                controller.keyLength.value == 24 ||
                                controller.keyLength.value == 32)
                            ? Colors.green[600]
                            : Colors.orange[700],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // IV输入框
  Widget _buildIvInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IV初始化向量（可选，留空使用默认）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller.ivController,
              onTap: () => controller.fillDefaultIv(),
              decoration: InputDecoration(
                hintText: '留空则使用默认IV: ${AESCONSTANT.IV}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 4),
            Obx(() => Text(
                  '当前长度: ${controller.ivLength.value} 字节（需要: 16 字节）',
                  style: TextStyle(
                    fontSize: 11,
                    color: controller.ivLength.value == 0
                        ? Colors.grey[500]
                        : controller.ivLength.value == 16
                            ? Colors.green[600]
                            : Colors.orange[700],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // 操作按钮
  Widget _buildActionButtons() {
    return Obx(() => Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: controller.clearAll,
                icon: const Icon(Icons.clear),
                label: const Text('清空'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: controller.isEncryptMode.value ? controller.performEncrypt : controller.performDecrypt,
                icon: Icon(controller.isEncryptMode.value ? Icons.lock : Icons.lock_open),
                label: Text(controller.isEncryptMode.value ? '加密' : '解密'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ));
  }

  // 结果显示
  Widget _buildResultCard() {
    return Obx(() {
      if (controller.errorMessage.value.isNotEmpty) {
        return Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    const Text(
                      '错误',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.result.value.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 32),
                const SizedBox(height: 6),
                Text(
                  '结果将显示在这里',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        controller.isEncryptMode.value ? '加密结果' : '解密结果',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: controller.result.value));
                      Get.snackbar('提示', '已复制到剪贴板');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Base64格式结果
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.isEncryptMode.value)
                    const Text(
                      'Base64格式:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  SelectableText(
                    controller.result.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              // 如果是加密结果，显示16进制格式
              if (controller.isEncryptMode.value && controller.resultHex.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '16进制格式:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: controller.resultHex.value));
                        Get.snackbar('提示', '已复制16进制到剪贴板');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  controller.resultHex.value,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
