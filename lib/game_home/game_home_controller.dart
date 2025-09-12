import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ycd/my_db/db_helper.dart';
import 'package:ycd/my_db/table1_model.dart';
import 'package:ycd/utils/loading.dart';
import 'package:ycd/utils/network/get_store.dart';

import '../my_db/table2_model.dart';
import '../routes/app_routes.dart';
import '../utils/bx_loading.dart';
import '../utils/network/api.dart';
import '../utils/network/http_mgr.dart';
import 'game_home_state.dart';
import 'game_home_view.dart';

class GameHomeController extends GetxController {
  EasyRefreshController refreshcontroller = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
  final GameState state = GameState();
  Future<Database>? _instance;

  final scrollController = ScrollController();
  final textEditingController = TextEditingController();
  final focusNode = FocusNode();

  FixedExtentScrollController? fixedExtentScrollController;

// 定义一个计时器，用于延时锁屏
  Timer? _timer;

  final ScrollController roadMapScrollController = ScrollController(); //路子图的controller

  @override
  void onInit() {
    super.onInit();
    WakelockPlus.enable();
    onUserInteraction();
    // _instance = DbHelper.instance.getDb();

    List.generate(32, (index) => state.totalValue.add('$index'));
    // //创建表
    // BXPost<Table1Model>(Api.createtables,
    //     success: (isSuccess, code, message, results) {
    //       if (isSuccess) queryAll();
    //       BXLoading.showToast(message);
    //     },
    //     failed: (p0, p1) => BXLoading.showToast(p1.msg),
    //     onModel: (m) => Table1Model.fromJson(m));
    textEditingController.addListener(
      () {
        state.bettingMoney = textEditingController.text;
        if (textEditingController.text.isNotEmpty) {
          ///总体
          state.totalValue[20] = pVal1();

          ///局部
          state.totalValue[24] = pVal2();
        }
      },
    );

    //1。查询表一数据
    _queryMysqlTable1();
    //2。起始要拿到统计区数据
    _getStatisticalAreasData(1); //传的有数据就是从传的数据的行开始计算
    //3。启始先查66条数据
    BXGet<Table2Model>(Api.loadMore,
        params: {"last_id": -1, "uid": GetStore.getInstance().userModel.userId, "c": 66}, //"c"每页多少个数据
        success: (isSuccess, code, message, results) {
          if (isSuccess && results.isNotEmpty) {
            state.table2ListX.clear();
            state.table2ListX = results.reversed.toList();
            var list = state.table2ListX.reversed
                .toList()
                .map((e) => e.colmunShuyingzhi!.startsWith("-") ? "闲家" : "庄家")
                .toList();
            debugPrint('-------> $list');
            for (var value in list) {
              updateBigRoad(value);
            }
            update();
          }
        },
        onModel: (m) => Table2Model.fromJson(m));
  }

  /// 更新大路图
  /// 根据百家乐大路规则更新大路图数据
  /// [winner] 本局获胜者（闲家/庄家/和局）
  ///
  /// 大路规则：
  /// - 和局不记录在大路中
  /// - 第一局记录在[0][0]位置
  /// - 与上局不同：向右移动（新列）
  /// - 与上局相同：向下移动（同列）
  /// - 长龙规则（标准）：同列向下，若到底或下方被占，则锁定当前行改为向右平移
  void updateBigRoad(String winner) {
    debugPrint('🐉️ 上局: ${state.lastWinner} 当前: $winner');

    // 和局不记录在大路中
    if (winner == '和局') {
      return;
    }

    /************如果是第一局，直接记录在第1行第1列 ********************************************** */
    if (state.lastWinner == '') {
      debugPrint('🐉️ 第一局，记录在 [${state.currentRow}][${state.currentCol}]');
      state.bigRoad[state.currentRow][state.currentCol] = winner;
      state.currentCol++;
    }

    /************ 如果与上一局不同，向右移动（新列）************************************************/
    else if (state.lastWinner != winner) {
      state.dragonStartCol = -1;
      state.dragonParallelRow = -1;
      state.currentRow = 0;
      state.bigRoad[state.currentRow][state.currentCol] = winner;
      debugPrint('🐉️ 与上一局不同，记录在 [${state.currentRow}][${state.currentCol}]');
      state.currentCol++;
    }

    /************ 如果与上一局相同，向下移动 *****************************************************/
    else {
      state.currentRow++;
      var ids = state.currentCol - 1; // 当前列的列

      // 如果下方有内容，或者已经超过6行，则需要往右平移（长龙处理）
      if ((state.currentRow < GameState.bigRoadRows && state.bigRoad[state.currentRow][ids].isNotEmpty) ||
          state.currentRow > GameState.bigRoadRows - 1) {
        // 长龙处理：向右平移
        state.dragonStartCol++;
        state.bigRoad[state.dragonParallelRow][state.dragonStartCol] = winner;
        debugPrint('🐉️（长龙处理）与上一局相同，记录在 [${state.dragonParallelRow}][${state.dragonStartCol}]');
      } else {
        // 没有超过6行，且下方没有内容，正常往下走
        state.bigRoad[state.currentRow][state.currentCol - 1] = winner;
        state.dragonParallelRow = state.currentRow; // 记录最后一次行
        state.dragonStartCol = state.currentCol - 1; // 记录最后一次列
        debugPrint('🐉️ 与上一局相同，记录在 [${state.currentRow}][${state.currentCol - 1}]');
      }
    }

    state.lastWinner = winner;
  }

  /// 自动滚动到当前绘制位置
  void scrollToCurrentPosition(int currentCol) {
    // 使用 addPostFrameCallback 保证在当前帧绘制完成后再执行滚动，避免滚动区域未布局完成导致异常
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (roadMapScrollController.hasClients) {
        // 计算当前列右边界的位置
        double currentColRightEdge = (currentCol + 1) * GameState.cellWidth;

        // 获取当前可见区域的右边界
        double currentScrollOffset = roadMapScrollController.position.pixels;
        double visibleRightEdge = currentScrollOffset + roadMapScrollController.position.viewportDimension;

        // 只有当当前列的右边界超出可见区域右边界时才滚动
        if (currentColRightEdge > visibleRightEdge) {
          // 计算需要滚动的距离，让当前列刚好可见
          double scrollDistance = currentColRightEdge - visibleRightEdge + GameState.cellWidth;
          double newOffset = currentScrollOffset + scrollDistance;

          // 确保不超过最大滚动范围
          double maxOffset = roadMapScrollController.position.maxScrollExtent;
          if (newOffset > maxOffset) {
            newOffset = maxOffset;
          }

          roadMapScrollController.animateTo(
            newOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _getStatisticalAreasData(int? tempIndex) {
    BXGet<dynamic>(
      Api.getStatisticalAreasData,
      params: {"tempIndex": tempIndex},
      success: (isSuccess, code, message, results) {
        state.totalValue = results.map((e) => e.toString()).toList();
        state.totalValue[28] = "${state.js1}/${state.js2}";
        //预测平均值
        if (textEditingController.text.isNotEmpty) {
          ///总体
          state.totalValue[20] = pVal1();

          ///局部
          state.totalValue[24] = pVal2();
        }
        state.isCanPress = true;
        update();
        getCharts();
      },
    );
  }

  showBottomFunction() {
    focusNode.nextFocus();
    fixedExtentScrollController = FixedExtentScrollController(initialItem: state.selectIndex);
    Get.bottomSheet(const SinglePicker());
  }

  String pVal2() {
    if (state.bettingMoney.isEmpty || !state.bettingMoney.isNum) return '';
    var x = double.parse(state.totalValue[18]); //总输赢
    var y = double.parse(state.bettingMoney); //输入框下注额
    var z = double.parse(removeChineseCharacters(state.totalValue[14])); //净胜
    var z1 = double.parse(removeChineseCharacters(state.totalValue[14])).abs(); //净胜绝对值
    if (z == 0) {
      return "回合结束";
    } else if (z > 0) /*赢>输的情况*/ {
      if ((z1 - 1) <= 0) {
        return '${((x + y) / (z1 + 1)).toStringAsFixed(1)}/';
      }
      return '${((x + y) / (z1 + 1)).toStringAsFixed(1)}/${((x - y) / (z1 - 1)).toStringAsFixed(1)}';
    } else {
      if ((z1 - 1) <= 0) {
        return '/${((x - y) / (z1 + 1)).toStringAsFixed(1)}';
      }
      return '${((x + y) / (z1 - 1)).toStringAsFixed(1)}/${((x - y) / (z1 + 1)).toStringAsFixed(1)}';
    }
  }

  String pVal1() {
    if (state.bettingMoney.isEmpty || !state.bettingMoney.isNum) return '';
    var x = double.parse(state.totalValue[17]); //总输赢
    var y = double.parse(state.bettingMoney); //输入框下注额
    var z = double.parse(removeChineseCharacters(state.totalValue[13])); //净胜
    var z1 = double.parse(removeChineseCharacters(state.totalValue[13])).abs(); //净胜绝对值
    if (z == 0) {
      return "回合结束";
    } else if (z > 0) /*赢>输的情况*/ {
      if ((z1 - 1) <= 0) {
        return '${((x + y) / (z1 + 1)).toStringAsFixed(1)}/';
      }
      return '${((x + y) / (z1 + 1)).toStringAsFixed(1)}/${((x - y) / (z1 - 1)).toStringAsFixed(1)}';
    } else {
      if ((z1 - 1) <= 0) {
        return '/${((x - y) / (z1 + 1)).toStringAsFixed(1)}';
      }
      return '${((x + y) / (z1 - 1)).toStringAsFixed(1)}/${((x - y) / (z1 + 1)).toStringAsFixed(1)}';
    }
  }

  @override
  void onClose() {
    // 取消计时器
    _timer?.cancel();
    super.onClose();
    WakelockPlus.disable();
    textEditingController.dispose();
  }

  setRandom(Function(int) f) {
    if (!state.isCanPress) {
      return;
    }
    state.isCanPress = false;
    state.js2 = state.js2 + 1;
    state.totalValue[28] = "${state.js1}/${state.js2}";
    update();
    // if (next(1, 90485) > 44625 - MyState.OFFSET8431) {
    if (next(1, 100) <= 50) {
      //1到100（包含1，100）//<= 70 是 70%庄 30%闲
      state.totalValue[30] = '庄';
      state.randomValue = '庄';
    } else {
      state.totalValue[30] = '闲';
      state.randomValue = '闲';
    }
    update();
    Get.dialog(NewWidget(state.randomValue),
        barrierDismissible: false, barrierColor: Colors.black.withValues(alpha: 0.18));
    state.isCanPress = true;
    update();
  }

  int next(int min, int max) => min + Random().nextInt(max - min + 1);

  _queryMysqlTable1() {
    BXGet<Table1Model>(Api.getTable1,
        isShowLoading: false,
        success: (isSuccess, code, message, value) {
          state.table1List.clear();
          if (value.isNotEmpty) {
            state.table1List = value;
            state.totalValue[0] = '${state.table1List.last.columnBenjin}'; //本金
            state.totalValue[19] = '${state.table1List.last.columnMean}'; //期望值
            state.chartData = List.generate(
                75, (index) => SalesData(index, double.parse(state.table1List.last.columnBenjin.toString()))).toList();
          }
          state.isRefreshing = false;
          update();
        },
        failed: (p0, p1) {
          refreshcontroller.finishRefresh(IndicatorResult.fail);
          state.isCanPress = true;
          state.isRefreshing = false;
        },
        onModel: (m) => Table1Model.fromJson(m));
  }

  recordButton(int i, String tableName, {Table1Model? table1, Table2Model? table2}) {
    // getDeviceId().then((value) {
    //   debugPrint('测试=》${value}');
    // });

    if (state.randomValue.isEmpty) {
      Get.snackbar("温馨提示", '请摇塞子',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.7));
      return;
    }

    if (state.bettingMoney.isEmpty) {
      Get.snackbar("温馨提示", '请输入下注金额',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.7));
      return;
    }
    if (!state.bettingMoney.isNum) {
      Get.snackbar("温馨提示", '请输入数字',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.7));
      return;
    }
    if (!state.isCanPress) {
      Get.snackbar("温馨提示", '速度太快',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white.withValues(alpha: 0.7));
      return;
    }
    Loading.show();
    state.isCanPress = false;
    state.js1 = state.js1 + 1;
    final table = tableName == 'table2'
        ? Table2Model(
            id: state.table2ListX.length + 1,
            //mysql数据库下标是从1开始的
            columnXiazhujine: state.bettingMoney,
            colmunZx: state.randomValue,
            //输（-） 赢 （+）
            colmunRemark: (i == 1 || i == 2) ? "1" : "-1",
            colmunShengfulu:
                ((i == 1 || i == 3) && (state.randomValue == '闲')) || ((i == 2 || i == 4) && (state.randomValue == '庄'))
                    ? "正打"
                    : "反打",
            colmunShuyingzhi: syzL(i),
            colmunShuyingzhiD: syzL(i),
            columnCurrentJin: getCurrentJin(i, double.parse(state.bettingMoney)).toString(),
          )
        : Table1Model(
            columnBenjin: "10000",
            columnYongJin: "0.95",
            columnMean: "0.08",
            columnRestartIndex: "0",
            columnLiushuiIndex: "10");

    ///改变成插入远程数据库
    if (tableName == 'table1') {
      BXPut<Table1Model>(Api.inserttable1,
          params: (table as Table1Model).toJson()
            ..addAll({"UserID": int.parse(GetStore.getInstance().userModel.userId)}),
          success: (isSuccess, code, message, results) => BXLoading.showToast("操作表1"),
          failed: (p0, p1) => state.isCanPress = true,
          onModel: (m) => Table1Model.fromJson(m));
    } else {
      BXPut<Table2Model>(Api.inserttable2,
          params: (table as Table2Model).toJson()
            ..remove("table2Id")
            ..addAll({"UserID": int.parse(GetStore.getInstance().userModel.userId)}),
          success: (isSuccess, code, message, results) {
            _getStatisticalAreasData(-2); //重新计算
            state.table2ListX.insert(0, results.first); //打一手 记录一笔
            updateBigRoad(state.table2ListX[0].colmunShuyingzhi!.startsWith("-") ? "闲家" : "庄家");
            // 自动滚动到当前位置
            scrollToCurrentPosition(state.currentCol);
          },
          failed: (p0, p1) => state.isCanPress = true,
          onModel: (m) => Table2Model.fromJson(m));
    }
  }

  getCharts() {
    var z = 0;
    BXGet<dynamic>(
      Api.getLinechartData,
      success: (isSuccess, code, message, results) {
        for (var i = results.length - 1; i >= 0; i--) {
          if (results[i].toString().isNotEmpty) {
            state.chartData[z].sales = double.parse(results[i]);
          }
          z++;
        }
        //解决外面的点跑，里面的线不动
        var removeLast = state.chartData.removeLast();
        Future.delayed(const Duration(milliseconds: 300), () {
          state.chartData.add(removeLast);
          update();
        });
      },
    );
  }

  getCurrentJin(int i, double playMoney) {
    var lastJinE = state.table2ListX.isEmpty ? 5000 : double.parse(state.table2ListX.first.columnCurrentJin.toString());
    switch (i) {
      case 1:
        return (lastJinE + playMoney);
      case 2:
        return (lastJinE) +
            playMoney *
                double.parse(
                    state.totalValue[31] == "31" || state.totalValue[31] == "" ? "0.95" : state.totalValue[31]);
      case 3:
      case 4:
        return (lastJinE) - playMoney;
    }
  }

  syzL(int i) {
    switch (i) {
      case 1: //闲
        return state.bettingMoney;
      case 2: //庄赢
        double parse = double.parse(state.bettingMoney);
        var xx = parse *
            double.parse(state.totalValue[31] == "31" || state.totalValue[31] == "" ? "0.95" : state.totalValue[31]);
        String syz /*庄赢值*/ = xx.toStringAsFixed(2); //四舍五入保留两位小数
        return syz;
      case 3:
      case 4:
        return '-${state.bettingMoney}';
    }
  }

  void deleteLast() {
    if (state.table2ListX.isNotEmpty) {
      Get.defaultDialog(
        barrierDismissible: false,
        title: '警告',
        content: const Text('确定删除最后一行数据？'),
        onCancel: () {},
        onConfirm: () {
          BXDelete<Table2Model>(Api.deletelast,
              success: (isSuccess, code, message, results) {
                _getStatisticalAreasData(-2);
                state.js1 = state.js1 - 1;
                state.totalValue[28] = "${state.js1}/${state.js2}";
                state.table2ListX.removeAt(0);
                update();
                Get.back();
              },
              onModel: (m) => Table2Model.fromJson(m));
        },
      );
    }
  }

  void updateLists(int index) {
    // _instance?.then((db) => db.update(DbHelper.table2, state.table2List[index].toJson()..update("colmun_shuyingzhi_d", (value) => "") /*具体更新的数据*/,
    //     where: "table2Id =?", //通过id查找需要更新的数据
    //     whereArgs: [index])).then((value) => _queryAllTable2());
    BXLoading.show();
    BXPost(
      Api.xiaoshu,
      isShowLoading: false,
      params: state.table2ListX[index].toJson()..update("colmun_shuyingzhi_d", (value) => ""),
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          state.table2ListX[index].colmunShuyingzhiD = "";
          Future.delayed(const Duration(milliseconds: 500), () {
            BXLoading.dismiss();
            update();
          });
        }
      },
    );
  }

  void reStart() {
    // _instance?.then((_db) => _db.query(DbHelper.table1).then((value) => _instance?.then((db) {
    //       //重启时，清除消数列数据
    //       for (int i = 0; i < state.table2List.length; i++) {
    //         db.update(DbHelper.table2, state.table2List[i].toJson()..update('colmun_shuyingzhi_d', (value) => ''),
    //             where: 'table2Id =?', whereArgs: [state.table2List[i].table2Id]);
    //       }
    //       return db
    //           .insert(
    //               DbHelper.table1,
    //               Table1Model(
    //                 columnBenjin: value.last['column_benjin'].toString(),
    //                 columnYongJin: value.last['column_yongJin'].toString(),
    //                 columnMean: value.last['column_mean'].toString(),
    //                 columnRestartIndex: "${state.table2List.length}",
    //                 columnLiushuiIndex: value.last['column_liushui_index'].toString(),
    //               ).toJson())
    //           .then((value) => queryAll());
    //     })));
    BXPost<Table1Model>(
      Api.restart,
      params: {"index": state.table2ListX.first.id},
      success: (isSuccess, code, message, value) {
        if (isSuccess) {
          // BXLoading.showToast("${value.last.columnRestartIndex}");
          state.table1List = value;
          state.table2ListX = state.table2ListX.map((element) => element..colmunShuyingzhiD = "").toList();
          _getStatisticalAreasData(-1);
          state.currentTempIndex = 0;
        }
      },
      onModel: (m) => Table1Model.fromJson(m),
    );
  }

  void updateBenJin(String b) {
    // _instance?.then((db) => db.query(DbHelper.table1).then((value) => _instance?.then((db) => db
    //     .insert(
    //         DbHelper.table1,
    //         Table1Model(
    //           columnBenjin: b,
    //           columnYongJin: value.last['column_yongJin'].toString(),
    //           columnMean: value.last['column_mean'].toString(),
    //           columnRestartIndex: value.last['column_restart_index'].toString(),
    //           columnLiushuiIndex: value.last['column_liushui_index'].toString(),
    //         ).toJson())
    //     .then((value) => queryAll()))));
    BXPost<Table1Model>(
      Api.updateBenjin,
      params: {"benjin": b},
      success: (isSuccess, code, message, value) {
        if (isSuccess) {
          BXLoading.showToast("${value.last.columnBenjin}");
          state.totalValue[0] = b;
          state.totalValue[4] = (double.parse(state.totalValue[0]) + double.parse(state.totalValue[17])).toString();
        }
      },
      onModel: (m) => Table1Model.fromJson(m),
    );
  }

  void updateOdds(String b) {
    // _instance?.then((db) => db.query(DbHelper.table1).then((value) => _instance?.then((db) => db
    //     .insert(
    //         DbHelper.table1,
    //         Table1Model(
    //           columnBenjin: value.last['column_benjin'].toString(),
    //           columnYongJin: b,
    //           columnMean: value.last['column_mean'].toString(),
    //           columnRestartIndex: value.last['column_restart_index'].toString(),
    //           columnLiushuiIndex: value.last['column_liushui_index'].toString(),
    //         ).toJson())
    //     .then((value) => queryAll()))));

    BXPost/*<Map<String,dynamic>>*/(Api.updateOdds, params: {"odds": b},
        success: (isSuccess, int code, String message, List<dynamic> results) {
      if (isSuccess) {
        BXLoading.showToast(message);
        debugPrint("赔率值是=${(results[0]["odds"])}");
        state.totalValue[31] = (results[0]["odds"]).toString();
        _getStatisticalAreasData(-2); //和recordButton里面传一样的参数，确保不会破坏局部平衡
      }
    });
  }

  //底部选项
  Future<void> functionConfirm(int i) async {
    var s = textEditingController.text.toString();
    switch (i) {
      case 0: //排列数据
        Loading.show();
        // var list =
        //     state.table2List.map((element) => element.colmunShuyingzhiD.toString().isEmpty ? 0.0 : double.parse(element.colmunShuyingzhiD.toString())).toList()
        //       ..removeWhere((element) => element == 0.0)
        //       ..sort();
        // _instance?.then((db) {
        //   var x = 0;
        //   for (int i = state.table2List.length - 1; i >= state.table2List.length - list.length; i--) {
        //     x++;
        //     if (x > list.length) {
        //       break;
        //     }
        //     db.update(DbHelper.table2, state.table2List[i].toJson()..update('colmun_shuyingzhi_d', (value) => '${list[list.length - x]}'),
        //         where: 'table2Id =?', whereArgs: [state.table2List[i].table2Id]);
        //   }
        // }).then((value) => _queryAllTable2());
        //改成接口
        BXPost(Api.sortxiaoshu, success: (isSuccess, code, message, results) {
          if (isSuccess) {
            BXLoading.showToast(message);
            var list = state.table2ListX
                .map((element) => element.colmunShuyingzhiD.toString().isEmpty
                    ? 0.0
                    : double.parse(element.colmunShuyingzhiD.toString()))
                .toList()
              ..removeWhere((element) => element == 0.0)
              ..sort();
            for (int i = 1; i <= list.length; i++) {
              state.table2ListX[i - 1].colmunShuyingzhiD = list[list.length - i].toString();
              update(); //调用了list里面的对象一定要用refresh()要不然不会刷新
            }
          }
        });
        break;
      case 1: //清除数据（消数列数据全部清除）
        // Loading.show();
        // _instance?.then((db) {
        //   for (int i = 0; i < state.table2List.length; i++) {
        //     if (state.table2List[i].colmunShuyingzhiD!.isEmpty) continue;
        //     db.update(DbHelper.table2, state.table2List[i].toJson()..update('colmun_shuyingzhi_d', (value) => ''),
        //         where: 'table2Id =?', whereArgs: [state.table2List[i].id]);
        //   }
        // }).then((value) => queryAll());
        int count = 0;
        for (var _ in state.table2ListX) {
          state.table2ListX[count].colmunShuyingzhiD = "";
          update();
          count++;
        }
        BXPost<dynamic>(
          Api.cleanDataD,
          params: {"uid": GetStore.getInstance().userModel.userId},
          success: (isSuccess, code, message, results) {
            if (isSuccess && results.isNotEmpty) {
              debugPrint("清除一共多少${results.first}条数据");
            }
          },
        );
        break;
      case 2: //修改本金
        Loading.show();
        if (s.isEmpty) {
          Loading.showToast(toast: '请输入金额 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          Loading.showToast(toast: '请输入数字 ${textEditingController.text} ');
          break;
        }
        updateBenJin(s);
        break;
      case 3: //修改位置
        Loading.show();
        state.js2 = state.js1;
        state.totalValue[28] = "${state.js1}/${state.js2}";
        Loading.dismiss();
        break;
      case 4: //删除本页

        // _instance?.then((db) {
        //   db.rawQuery('DELETE FROM ${DbHelper.table1}');
        //   return db.rawQuery('DELETE FROM ${DbHelper.table2}');
        // }).then((value) => dropAll());

        Get.defaultDialog(
          barrierDismissible: false,
          title: '警告',
          content: const Text('是否删除全部数据'),
          onCancel: () {},
          onConfirm: () {
            Loading.show();
            BXDelete(Api.deleteall, success: (isSuccess, code, message, results) {
              if (isSuccess) {
                BXLoading.showToast(message);
                state.table1List.clear();
                state.table2ListX.clear();
                state.randomValue = '';
                List.generate(32, (index) => state.totalValue[index] = index.toString());
                _getStatisticalAreasData(-1);
              }
            });
            Get.back();
          },
        );
        break;
      case 5: //重置流水
        BXPost(
          Api.resetliushui,
          params: {"resetIndex": (state.table2ListX.first.id)},
          success: (bool isSuccess, int code, String message, List<dynamic> results) {},
        );
        break;
      case 6: //备份数据
        Loading.show();
        final Directory documentsDirectory = await getApplicationDocumentsDirectory();
        final Directory tempDir = await getTemporaryDirectory();
        final Directory? downloadsDir = await getDownloadsDirectory();
        debugPrint(documentsDirectory.path);
        debugPrint(tempDir.path);
        debugPrint(downloadsDir?.path);

        _instance?.then((db) => db.query(DbHelper.table1)).then((value1) => _instance
            ?.then((db) => db.query(DbHelper.table2))
            .then((value2) => saveString('${jsonEncode(value1)}\n${jsonEncode(value2)}')));

        break;
      case 7:
        // Get.defaultDialog(
        //   barrierDismissible: false,
        //   title: '警告',
        //   content: const Text('是否重启'),
        //   onCancel: () {},
        //   onConfirm: () {
        Loading.show();
        reStart();
        Get.back();
        // },
        // );
        break;
      case 8: //修改期望值
        if (s.isEmpty) {
          Loading.showToast(toast: '请输入期望值 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          Loading.showToast(toast: '请输入数字 ${textEditingController.text} ');
          break;
        }
        updateQiWangZhi(s);
        break;
      case 9: //恢复数据
        Loading.show();
        getString();
        break;
      case 10: //修改赔率
        Loading.show();
        if (s.isEmpty) {
          Loading.showToast(toast: '请输入赔率 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          Loading.showToast(toast: '请输入赔率 ${textEditingController.text} ');
          break;
        }
        updateOdds(s);
        break;
      case 11: //退出程序
        GetStore.getInstance().cleanUser();
        Get.offAndToNamed(AppRoutes.login);
        break;
    }
  }

  void dropAll() {
    state.table2ListX.clear();
    state.randomValue = '';
    List.generate(32, (index) => state.totalValue[index] = index.toString());
    _instance
        ?.then((db) => db.insert(
            DbHelper.table1,
            Table1Model(
                    columnBenjin: "5000",
                    columnYongJin: "0.95",
                    columnMean: "0.08",
                    columnRestartIndex: "0",
                    columnLiushuiIndex: "0")
                .toJson()))
        .then((value) => Loading.dismiss());
  }

  void updateQiWangZhi(String qiwangzhi) {
    BXPost/*<Map<String,dynamic>>*/(Api.updateQiWangValue, params: {"mean": qiwangzhi},
        success: (isSuccess, int code, String message, List<dynamic> results) {
      if (isSuccess) {
        BXLoading.showToast(message);
        debugPrint("期望值是=${(results[0]["mean"])}");
        state.totalValue[19] = (results[0]["mean"]).toString();
      }
    });
  }

  /// 利用文件存储数据
  saveString(String s) async {
    final file = await getFile('file.text');
    //写入字符串
    file.writeAsString(s).then((value) {
      Loading.dismiss();
      debugPrint('=====备份完成=====');
    });
  }

  /// 获取存在文件中的数据
  Future getString() async {
    final file = await getFile('file.text');
    if (!await file.exists()) {
      Loading.dismiss();
      Loading.showToast(toast: '文件不存在');
      return;
    }
    var filePath = file.path;
    file.readAsString().then((String value) {
      var s = '文件存储路径：$filePath';
      debugPrint(s);
      var split1 = value.split('\n')[0];
      debugPrint(jsonDecode(split1).length);
      debugPrint(split1);
      var split2 = value.split('\n')[1];
      debugPrint(jsonDecode(split2).length);
      debugPrint(split2);
      for (var element in jsonDecode(split1)) {
        _instance?.then((db) => db.insert(DbHelper.table1, element));
      }
      for (var element in jsonDecode(split2)) {
        _instance?.then((db) => db.insert(DbHelper.table2, element));
      }
      debugPrint('=====写入数据库完成====');
    });
  }

  /// 初始化文件路径
  Future<File> getFile(String fileName) async {
    //获取应用文件目录类似于Ios的NSDocumentDirectory和Android上的 AppData目录
    final fileDirectory = await getApplicationDocumentsDirectory();

    //获取存储路径
    final filePath = fileDirectory.path;

    //或者file对象（操作文件记得导入import 'dart:io'）
    return File("$filePath/$fileName");
  }

  lockScreen() {
    _timer?.cancel();
    _timer = null;
    screenLock(
      config: const ScreenLockConfig(
        backgroundColor: Colors.black,
      ),
      onValidate: (input) => getFuture(input),
      secretsConfig: const SecretsConfig(
        spacing: 15, // or spacingRatio
        padding: EdgeInsets.all(40),
        //输入密码框的配置
        // secretConfig: SecretConfig(
        //   borderColor: Colors.red,
        //   borderSize: 1.0,
        //   disabledColor: Colors.black,
        //   enabledColor: Colors.red,
        // ),
      ),
      title: const Icon(Icons.lock, size: 30, color: Colors.white),
      context: Get.context!,
      correctString: '1234',
      canCancel: false,
      //是否可以取消
      onUnlocked: () {
        Get.back();
        onUserInteraction();
      },
    );
  }

  void onUserInteraction() {
    // 取消之前的计时器
    _timer?.cancel();
    // 设置新的计时器，时间设置为你想要的锁屏延时时间
    _timer = Timer(const Duration(seconds: 60 * 2), () {
      lockScreen();
    });
  }

  getFuture(String input) => Future.delayed(const Duration(milliseconds: 200), () {
        if (input.length == 4 && input == "0000") {
          return true;
        } else {
          Loading.showError(toast: '密码错误');
          return false;
        }
      });

  Future<String?> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // deviceId = androidInfo.board;
      // deviceId = androidInfo.hardware;//mt6762
      // deviceId = androidInfo.product;//dandelion
      // deviceId = androidInfo.tags;//release-keys
      deviceId = androidInfo.device; //release-keys
      debugPrint(androidInfo.data.toString());
      deviceId = androidInfo.device; //release-keys
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // iOS没有设备ID的概念，但可以使用idfv来获取用户标识符
      deviceId = iosInfo.identifierForVendor;
    }

    return deviceId;
  }

  juBuPingHeng(int index, {v}) {
    if (index == -1) {
      state.currentTempIndex = 0;
    } else {
      state.currentTempIndex = index;
    }
    update();
    if (state.table2ListX.isNotEmpty) _getStatisticalAreasData(index);
    Future.delayed(const Duration(milliseconds: 1000), () {
      state.totalValue[30] = v.toString();
      update();
    });
  }

  //下拉刷新
  void onRefresh() {
    state.isRefreshing = true;
    _queryMysqlTable1();
  }

  //加载更多
  void onLoadMore() {
    BXGet<Table2Model>(Api.loadMore,
        params: {
          "last_id": state.table2ListX.last.id,
          "uid": GetStore.getInstance().userModel.userId,
          "c": 10
        }, //"c"每页多少个数据
        success: (isSuccess, code, message, results) {
          if (isSuccess && results.isNotEmpty) {
            var temp = <Table2Model>[];
            temp.addAll(results);
            temp.addAll(state.table2ListX.reversed.toList());
            state.table2ListX.clear();
            state.table2ListX = temp.reversed.toList();
            update();
          }
          refreshcontroller.finishLoad(IndicatorResult.success, isSuccess);
        },
        onModel: (m) => Table2Model.fromJson(m));
  }

  changeChart() {
    state.isBigRoad = !state.isBigRoad;
    update();
  }
}

class NewWidget extends StatefulWidget {
  final String title;

  const NewWidget(
    this.title, {
    super.key,
  });

  @override
  State<NewWidget> createState() => _NewWidgetState();
}

class _NewWidgetState extends State<NewWidget> {
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    timer ??= Timer.periodic(const Duration(milliseconds: 500), (timer) => setState(() => Get.back()));
    return Center(
      child: Text(
        widget.title,
        style: const TextStyle(fontSize: 90),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

String removeChineseCharacters(String input) {
  return input.replaceAll(RegExp('[\u4e00-\u9fa5]'), '');
}
