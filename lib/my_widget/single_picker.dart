import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ycd/views/ji_shu_qi/ji_shu_qi_controller.dart';

class SinglePicker extends StatefulWidget {
  const SinglePicker({super.key, this.darkTextColor});

  final Color? darkTextColor;

  @override
  State<StatefulWidget> createState() => _SinglePickerState();
}

class _SinglePickerState extends State<SinglePicker> {
  final controller = Get.find<JiShuQiController>();
  int selectIndex = 0;

  @override
  void initState() {
    selectIndex = controller.state.selectIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: controller.state.currentBgColor,
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
                style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent)),
                child: Text(
                  "确定",
                  style: TextStyle(
                    color: controller.state.isDarkMode
                        ? Colors.orange
                        : Colors.redAccent,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          GetBuilder<JiShuQiController>(
              builder: (controller) => Expanded(
                    child: CupertinoPicker(
                        scrollController:
                            controller.fixedExtentScrollController,
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
                                color: controller.state.isDarkMode
                                    ? widget.darkTextColor ?? Colors.white
                                    : Colors.black,
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
