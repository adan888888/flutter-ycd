import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/views/game/game_controller.dart';

class SinglePicker extends StatefulWidget {
  const SinglePicker({super.key});

  @override
  State<StatefulWidget> createState() => _SinglePickerState();
}

class _SinglePickerState extends State<SinglePicker> {
  final controller = Get.find<GameController>();
  int selectIndex = 0;

  @override
  void initState() {
    selectIndex = controller.state.selectIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: controller.state.isDarkMode ? const Color(0xFF1E2A3A) : Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.functionConfirm(selectIndex);
                },
                style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.transparent)),
                child: Text(
                  "确定",
                  style: TextStyle(
                    color: controller.state.isDarkMode ? Colors.orange : Colors.redAccent,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          GetBuilder<GameController>(
              builder: (controller) => Expanded(
                    child: CupertinoPicker(
                        scrollController: controller.fixedExtentScrollController,
                        itemExtent: 50, // 每个选项的高度
                        onSelectedItemChanged: (int index) {
                          // 处理选中项的变化
                          selectIndex = index;
                        },
                        children: List.generate(
                          controller.state.functionTypes.length,
                          (index) => Align(
                            alignment: Alignment.center,
                            child: Text(
                              controller.state.functionTypes[index].toString(),
                              style: TextStyle(
                                color: controller.state.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        )),
                  ))
        ],
      ),
    );
  }
}
