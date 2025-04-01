import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_controller.dart';

class LoginWidget extends GetView<LoginController> {
  const LoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final state = Get.find<LoginController>().state;
    return Scaffold(
      appBar: AppBar(title: const Text("登录")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: "邮箱",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "请输入邮箱";
                  }
                  /*else if (!RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+").hasMatch(value)) {
                    return "请输入有效的邮箱地址";
                  }*/
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.userNameController,
                decoration: const InputDecoration(
                  labelText: "用户名",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "请输入用户名";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.passwordController,
                decoration: const InputDecoration(
                  labelText: "密码",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "请输入密码";
                  } else if (value.length < 2) {
                    return "密码长度至少6位";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: controller.login,
                child: const Text("登 录"),
              ),
              const SizedBox(height: 24),
              // ElevatedButton(
              //   onPressed: _logout,
              //   child: const Text("退出"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
