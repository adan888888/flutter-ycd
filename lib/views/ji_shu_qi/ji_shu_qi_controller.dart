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
import 'package:ycd/model/linechart_data_model.dart';
import 'package:ycd/my_db/db_helper.dart';
import 'package:ycd/my_db/table1_model.dart';
import 'package:ycd/my_db/table2_model.dart';
import 'package:ycd/my_widget/custom_dialog.dart';
import 'package:ycd/my_widget/single_picker.dart';
import 'package:ycd/routes/app_routes.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/utils/loading.dart';
import 'package:ycd/utils/my_character.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/network/http_mgr.dart';

import 'ji_shu_qi_state.dart';

class JiShuQiController extends GetxController {
  EasyRefreshController refreshcontroller = EasyRefreshController(controlFinishRefresh: true, controlFinishLoad: true);
  final JiShuQiState state = JiShuQiState();
  Future<Database>? _instance;

  final scrollController = ScrollController();
  final textEditingController = TextEditingController();
  final focusNode = FocusNode();

  FixedExtentScrollController? fixedExtentScrollController;

// 定义一个计时器，用于延时锁屏
  Timer? _timer;

  final ScrollController roadMapScrollController = ScrollController(); //路子图的controller

  /// 并发多次 [_getLineCharts] 时仅采纳最近一次发起的 `linechartData` 回调，避免旧响应把已画好的曲线冲掉。
  int _lineChartRequestGen = 0;

  @override
  void onInit() {
    super.onInit();
    WakelockPlus.enable();
    onUserInteraction();

    List.generate(32, (index) => state.totalValue.add('$index'));
    textEditingController.addListener(
      () {
        state.bettingMoney = textEditingController.text;
        if (textEditingController.text.isNotEmpty) {
          ///总体
          state.totalValue[20] = pVal1();

          ///局部
          state.totalValue[24] = pVal2();
          update();
        }
      },
    );

    //1。查询表一数据
    _queryMysqlTable1();
    //2。起始要拿到统计区数据
    _getStatisticalAreasData(-10000);
    //3。起始先查66条数据（与 [_reloadBettingListTail] 逻辑一致）
    _reloadBettingListTail();
  }

  /// 按最新一页重新拉取投注记录（`last_id: -1`，与进入页面时一致）。
  /// [minCount] 至少条数；若已通过上拉加载更多历史，则用当前条数避免刷新后列表变短。
  /// **局部平衡锚点 id 若不在本窗口内**：不扩列表、不特殊处理；该行不在 `table2List` 时眼睛不出现即可。
  Future<void> _reloadBettingListTail({int minCount = 66}) async {
    final completer = Completer<void>();
    final n = state.table2List.length > minCount ? state.table2List.length : minCount;
    BXGet<Table2Model>(
      Api.loadMore,
      params: {"last_id": -1, "uid": GetStore.getInstance().userModel.userId, "c": n},
      success: (isSuccess, code, message, results) {
        if (isSuccess && results.isNotEmpty) {
          state.table2List.clear();
          state.table2List = List<Table2Model>.from(results);
          _reloadLuZiTu();
          if (!state.isBigRoad) {
            _getLineCharts(applyStatsTail: true);
          }
          update();
          scrollBettingListToBottom();
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      failed: (_, __) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      isShowLoading: false,
      onModel: (m) => Table2Model.fromJson(m),
    );
    return completer.future;
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
      if ((state.currentRow < JiShuQiState.bigRoadRows && state.bigRoad[state.currentRow][ids].isNotEmpty) ||
          state.currentRow > JiShuQiState.bigRoadRows - 1) {
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
  void scrollToCurrentPosition() {
    // 使用 addPostFrameCallback 保证在当前帧绘制完成后再执行滚动，避免滚动区域未布局完成导致异常
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (roadMapScrollController.hasClients) {
        // 计算当前列右边界的位置(这样计算还是有点不准，能在整个数据里找到最右边的列才更准，不过实际中应该没有那长的龙，先就这样吧)
        double currentColRightEdge =
            (state.dragonStartCol == -1 ? state.currentCol : state.dragonStartCol + 1) * JiShuQiState.cellWidth;

        double currentScrollOffset = roadMapScrollController.position.pixels /* 当前滚动位置（滑动了多少）*/;
        /* 当前滚动位置 + 可见区域尺寸 = 可见区域右边界 */
        double visibleRightEdge = currentScrollOffset + roadMapScrollController.position.viewportDimension /* 可见区域尺寸 */;

        // 只有当当前列的右边界超出可见区域右边界时才滚动
        if (currentColRightEdge > visibleRightEdge) {
          // 计算需要滚动的距离，让当前列刚好可见
          double scrollDistance = currentColRightEdge - visibleRightEdge + JiShuQiState.cellWidth;
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

  /// 路子图数据变更后调度滚动：`update()` 之后 extent 可能尚未更新，多帧 + 短延迟与投注列表兜底一致。
  void _scheduleRoadMapScrollAfterRebuild() {
    if (!state.hasBigRoadData) return;
    void tick() => scrollToCurrentPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tick();
      WidgetsBinding.instance.addPostFrameCallback((_) => tick());
    });
    Future.delayed(const Duration(milliseconds: 50), tick);
    Future.delayed(const Duration(milliseconds: 180), tick);
  }

  /// 投注列表时间升序（最新在底部）。多帧 + 延迟重试，避免刚 `update()` 后 extent 未算准、或未挂上 Scrollable。
  void scrollBettingListToBottom() {
    void jumpToEnd() {
      if (!scrollController.hasClients) return;
      final max = scrollController.position.maxScrollExtent;
      if (!max.isFinite || max < 0) return;
      scrollController.jumpTo(max);
    }

    /// 仍未挂上 Scrollable；或已与底部相差较大：再试。extent 尚为 0 但条数较多时视为未布局完。
    bool needsAnotherTry() {
      if (!scrollController.hasClients) return state.table2List.isNotEmpty;
      if (state.table2List.isEmpty) return false;
      final pos = scrollController.position;
      final max = pos.maxScrollExtent;
      if (!max.isFinite) return true;
      if (max <= 0.5) {
        return state.table2List.length > 8;
      }
      return max - pos.pixels > 1.5;
    }

    void scheduleFrames(int left) {
      if (left <= 0) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpToEnd();
        final more = needsAnotherTry() && left > 1;
        if (more) scheduleFrames(left - 1);
      });
    }

    scheduleFrames(10);
    Future.delayed(const Duration(milliseconds: 50), jumpToEnd);
    Future.delayed(const Duration(milliseconds: 180), jumpToEnd);
    Future.delayed(const Duration(milliseconds: 420), jumpToEnd);
  }

  /// 顶部插入历史行后恢复视口：用固定行高累计增量（避免 LazyList / EasyRefresh 回弹时 maxScrollExtent 不准）。
  /// 下拉刷新时 [keptPixels] 可能为负，按 0 处理。
  void _schedulePreserveScrollAfterPrepend(double keptPixels, int insertedCount) {
    if (insertedCount <= 0 || !keptPixels.isFinite) return;
    final delta = JiShuQiState.bettingTableRowHeight * insertedCount;
    final base = keptPixels < 0 ? 0.0 : keptPixels;

    void apply() {
      if (!scrollController.hasClients) return;
      final maxS = scrollController.position.maxScrollExtent;
      if (!maxS.isFinite) return;
      scrollController.jumpTo((base + delta).clamp(0.0, maxS));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    });
    // EasyRefresh 收起头部时还会改一次 offset，晚一点再对齐
    Future.delayed(const Duration(milliseconds: 320), apply);
    Future.delayed(const Duration(milliseconds: 560), apply);
  }

  /// 局部平衡锚点（投注列表「眼睛」行 id）：以后端 **table_yanchendao1.temp_index** 为准，
  /// 对应客户端 `table1List.last.tempIndex`；值为整数且 **>2** 视为有效 table2 主键 id。
  /// **temp_index 为 -1**：取消局部平衡，`currentTempIndex` 固定为 **0**。
  /// 若无 table1 数据则退回统计接口回填的 `totalValue[29]`（兼容冷启动顺序）。
  /// **锚点 id 不在当前 `table2List` 时**：不处理列表窗口（不保证眼睛可见）；仅保持 `currentTempIndex` 与配置一致。
  void _syncLocalTempIndexWithBackendState() {
    if (state.table1List.isNotEmpty) {
      final raw = state.table1List.last.tempIndex?.trim() ?? '';
      final v = int.tryParse(raw);
      // 后端 temp_index 为 -1：取消局部平衡，锚点归零
      if (v == -1) {
        state.currentTempIndex = 0;
        return;
      }
      state.currentTempIndex = (v != null && v > 2) ? v : 0;
      return;
    }
    if (state.totalValue.length > 29) {
      final raw = state.totalValue[29].toString().trim();
      if (raw.isEmpty) return;
      final v = int.tryParse(raw);
      if (v == -1) {
        state.currentTempIndex = 0;
        return;
      }
      if (v != null && v > 2) {
        state.currentTempIndex = v;
      }
    }
  }

  /// *
  ///  tempIndex -10000 app第一次进来
  ///  tempIndex -1 取消局部平衡/重启...
  ///  tempIndex -2 确保不会破坏局部平衡-->每次下注后（recordbutton() ，改变数据库里面的值等 ...）
  ///  tempIndex >2 点击进行局部平衡
  ///
  Future<void> _getStatisticalAreasData(int? tempIndex) {
    final completer = Completer<void>();
    BXGet<dynamic>(
      Api.getStatisticalAreasData,
      params: {"tempIndex": tempIndex},
      success: (isSuccess, code, message, results) {
        state.totalValue = results.map((e) => e.toString()).toList();
        state.totalValue[28] = "${state.js1}/${state.js2}";

        void continueAfterStatsReady() {
          _syncLocalTempIndexWithBackendState();
          //预测平均值
          if (textEditingController.text.isNotEmpty) {
            ///总体
            state.totalValue[20] = pVal1();

            ///局部
            state.totalValue[24] = pVal2();
          }
          state.isCanPress = true;

          if (state.isBigRoad) {
            _reloadLuZiTu(); //路子图直接在本地的数据处理
            update();
          } else {
            // 统计区 totalValue[4] 由服务端按全表重算，用作折线最右一点，避免与 column_current_jin 漂移（如大输赢后末端不更新）
            _getLineCharts(applyStatsTail: true);
          }
          _delayedTask(); //必须要提一个方法放出去，不然会会卡下面的代码
          if (!completer.isCompleted) {
            completer.complete();
          }
        }

        // 取消局部平衡(-1) 或 选中锚点行(>2) 时后端会更新 table1.temp_index；须先拉 table1 再同步，
        // 否则会沿用内存里旧的 temp_index，把 currentTempIndex 又写回去（取消失效）。
        final ti = tempIndex;
        final needsFreshTable1 = ti == -1 || (ti != null && ti > 2);
        if (needsFreshTable1) {
          _queryMysqlTable1().then((_) => continueAfterStatsReady()).catchError((_) => continueAfterStatsReady());
        } else {
          continueAfterStatsReady();
        }
      },
      failed: (message, _) {
        state.isCanPress = true;
        if (!completer.isCompleted) {
          completer.completeError(message);
        }
      },
    );
    return completer.future;
  }

  Future<void> _delayedTask() async {
    Future.delayed(const Duration(milliseconds: 300), () {
      state.totalValue[29] = state.randomValue;
      update();
    });
  }

  showBottomFunction() {
    focusNode.nextFocus();
    fixedExtentScrollController = FixedExtentScrollController(initialItem: state.selectIndex);
    Get.bottomSheet(const SinglePicker());
  }

  String pVal2() {
    if (state.bettingMoney.isEmpty || !state.bettingMoney.isNum) return '';
    var val = state.randomValue == '庄'
        ? (double.parse(textEditingController.text) * double.parse(state.totalValue[31])).toStringAsFixed(2)
        : textEditingController.text;
    var x = double.parse(state.totalValue[18]); //总输赢
    var y = double.parse(val); //输入框下注额
    var z = double.parse(MyCharacter.removeChineseCharacters(state.totalValue[14])); //净胜
    var z1 = double.parse(MyCharacter.removeChineseCharacters(state.totalValue[14])).abs(); //净胜绝对值
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
    var val = state.randomValue == '庄'
        ? (double.parse(textEditingController.text) * double.parse(state.totalValue[31])).toStringAsFixed(2)
        : textEditingController.text;
    var x = double.parse(state.totalValue[17]); //总输赢
    var y = double.parse(val); //输入框下注额
    var z = double.parse(MyCharacter.removeChineseCharacters(state.totalValue[13])); //净胜
    var z1 = double.parse(MyCharacter.removeChineseCharacters(state.totalValue[13])).abs(); //净胜绝对值
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
    BXGet(
      Api.randomBankerPlayer,
      success: (isSuccess, code, message, results) {
        var result = (results.first as Map)["result"].toString();

        if (result.isNotEmpty) {
          state.randomValue = state.totalValue[29] = result;
        } else {
          // if (next(1, 90485) > 44625 - MyState.OFFSET8431) {
          //1到100（包含1，100）//<= 70 是 70%庄 30%闲
          if (_next(1, 100) <= state.ratio) {
            state.randomValue = state.totalValue[29] = '庄';
          } else {
            state.randomValue = state.totalValue[29] = '闲';
          }
        }
        Get.dialog(
          ZhuangXianDialog(state.randomValue),
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.18),
        );
        state.isCanPress = true;
        update();
      },
      isShowLoading: false, // 使用自定义的Loading
    );
  }

  _next(int min, int max) => min + Random().nextInt(max - min + 1);

  Future<void> _queryMysqlTable1() {
    final completer = Completer<void>();
    BXGet<Table1Model>(Api.getTable1,
        isShowLoading: false,
        success: (isSuccess, code, message, value) {
          state.table1List.clear();
          if (value.isNotEmpty) {
            state.table1List = value;
            state.totalValue[0] = '${state.table1List.last.columnBenjin}'; //本金
            state.totalValue[19] = '${state.table1List.last.columnMean}'; //期望值
            // 折线形状必须由 [_getLineCharts]（table2 末尾或 linechartData）提供；此处若用本金铺满 75 点，
            // 会在接口已画出真实曲线之后覆盖成一条水平线（本金为 0 时即为「全 0」）。
            _syncLocalTempIndexWithBackendState();
          } else {
            state.currentTempIndex = 0;
          }
          update();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        failed: (p0, p1) {
          refreshcontroller.finishRefresh(IndicatorResult.fail);
          state.isCanPress = true;
          if (!completer.isCompleted) {
            completer.completeError(p0);
          }
        },
        onModel: (m) => Table1Model.fromJson(m));
    return completer.future;
  }

  betRecordButton(int i, String tableName, {Table1Model? table1, Table2Model? table2}) {
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
            id: state.table2List.length + 1,
            //mysql数据库下标是从1开始的
            columnXiazhujine: state.bettingMoney,
            //记录开出的庄闲
            colmunZx: (i == 2 || i == 3) ? '庄' : '闲',
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
          isShowLoading: false,
          params: (table as Table2Model).toJson()
            ..remove("table2Id")
            ..addAll({"UserID": int.parse(GetStore.getInstance().userModel.userId)}),
          success: (isSuccess, code, message, results) {
            if (results.isNotEmpty) {
              state.table2List.add(results.first..seq = state.table2List.last.seq! + 1);
            }
            update(); // 先让 ListView 用新 itemCount 布局，再滚到底才准
            scrollBettingListToBottom();
            _getStatisticalAreasData(-2); //重新计算（回调里会带 applyStatsTail 刷新折线末端）
          },
          failed: (p0, p1) => state.isCanPress = true,
          onModel: (m) => Table2Model.fromJson(m));
    }
  }

  /// 折线：需要完整 75 个点。
  /// - 本地已加载 ≥75 条时，用 table2List 末尾 75 条（时间升序，与列表一致）。
  /// - 否则（如首屏只拉 66 条）走 linechartData 接口，从库中取最近 75 笔（id 降序返回，从尾到头填入）。
  /// - [applyStatsTail]：在刚从统计接口回填后，将最右一点强制为 [totalValue[4]]（本金+累计输赢），与统计区「当前金额」一致。
  void _getLineCharts({bool applyStatsTail = false}) {
    final gen = ++_lineChartRequestGen;
    final benjin = state.table1List.isNotEmpty ? double.tryParse(state.table1List.last.columnBenjin.toString()) : null;
    void resetChartPad(double p) {
      if (state.chartData.length != 75) {
        state.chartData = List.generate(75, (index) => LineChartDataModel(index, p));
      } else {
        for (var i = 0; i < 75; i++) {
          state.chartData[i].sales = p;
        }
      }
    }

    final pad = benjin ?? (state.chartData.isNotEmpty ? state.chartData[0].sales : 0.0);
    resetChartPad(pad);

    final list = state.table2List;
    if (list.length >= 75) {
      final n = list.length;
      final start = n - 75;
      for (var k = 0; k < 75; k++) {
        final v = list[start + k].columnCurrentJin;
        if (v != null && v.isNotEmpty) {
          final parsed = double.tryParse(v);
          if (parsed != null) {
            state.chartData[k].sales = parsed;
          }
        }
      }
      if (applyStatsTail) {
        _syncChartLastPointWithTotalValue();
      }
      update();
      return;
    }

    BXGet<dynamic>(
      Api.getLinechartData,
      success: (isSuccess, code, message, results) {
        if (gen != _lineChartRequestGen) return;
        if (!isSuccess) return;
        resetChartPad(benjin ?? (state.chartData.isNotEmpty ? state.chartData[0].sales : 0.0));
        var z = 0;
        for (var i = results.length - 1; i >= 0 && z < state.chartData.length; i--) {
          if (results[i].toString().isNotEmpty) {
            state.chartData[z].sales = double.parse(results[i].toString());
          }
          z++;
        }
        if (applyStatsTail) {
          _syncChartLastPointWithTotalValue();
        }
        update();
      },
      isShowLoading: false, // 第二个接口不显示loading，避免重复显示
    );
  }

  /// 与统计区 [totalValue[4]] 对齐折线最右端（第 75 点），对应服务端「本金 + 全表输赢累计」。
  void _syncChartLastPointWithTotalValue() {
    if (state.chartData.length != 75) return;
    if (state.totalValue.length <= 4) return;
    final raw = MyCharacter.removeChineseCharacters(state.totalValue[4].toString()).trim();
    if (raw.isEmpty) return;
    final v = double.tryParse(raw);
    if (v != null) {
      state.chartData[74].sales = v;
    }
  }

  getCurrentJin(int i, double playMoney) {
    var lastJinE = state.table2List.isEmpty ? 5000 : double.parse(state.totalValue[4].toString());
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
      case 2: //庄赢：下注×赔率（不含加回本金）。注意不可用 toStringAsFixed(2)，否则 0.095 会变成 0.10
        double parse = double.parse(state.bettingMoney);
        final xx = parse *
            double.parse(state.totalValue[31] == "31" || state.totalValue[31] == "" ? "0.95" : state.totalValue[31]);
        return _formatZhuangYingShuying(xx);
      case 3:
      case 4:
        return '-${state.bettingMoney}';
    }
  }

  /// 庄赢输赢字符串：去掉末尾多余 0，避免 0.095 被格式化成与 0.1 混淆。
  String _formatZhuangYingShuying(double value) {
    final s = value.toStringAsFixed(8); //四舍五入到8位小数
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void deleteLast() {
    if (state.table2List.isNotEmpty) {
      Get.defaultDialog(
        barrierDismissible: false,
        backgroundColor: state.isDarkMode ? const Color(0xFF1E2A3A) : Colors.white,
        title: '警告',
        content: Text(
          '确定删除最后一行数据？',
          style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
        ),
        titleStyle: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
        contentPadding: const EdgeInsets.all(20),
        onCancel: () {},
        onConfirm: () {
          BXDelete<Table2Model>(Api.deletelast,
              success: (isSuccess, code, message, results) {
                _getStatisticalAreasData(-2);
                state.js1 = state.js1 - 1;
                state.totalValue[28] = "${state.js1}/${state.js2}";
                state.table2List.removeLast();
                _reloadLuZiTu();
                Get.back();
                update();
              },
              onModel: (m) => Table2Model.fromJson(m));
        },
      );
    }
  }

  void updateLists(int index) {
    BXLoading.show();
    BXPost(
      Api.xiaoshu,
      isShowLoading: false,
      params: state.table2List[index].toJson()..update("colmun_shuyingzhi_d", (value) => ""),
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          state.table2List[index].colmunShuyingzhiD = "";
          Future.delayed(const Duration(milliseconds: 500), () {
            BXLoading.dismiss();
            update();
          });
        }
      },
    );
  }

  /// 重启前从统计区取 2/6/14/18 拼接快照（须在调用 restart 接口之前），
  /// 其中 index 18 四舍五入保留 1 位小数。
  String _buildRestartStatSnapshot() {
    const indices = [2, 6, 14, 18];
    return indices.map((i) {
      if (i >= state.totalValue.length) return '';
      final raw = MyCharacter.removeChineseCharacters(state.totalValue[i].toString()).trim();
      if (i != 18) return raw;
      final v = double.tryParse(raw);
      return v == null ? raw : v.toStringAsFixed(1);
    }).join('/');
  }

  /// 当前回合是否无数据（看统计区「回合局数」totalValue[2]）
  bool _isRoundStatsEmpty() {
    if (state.totalValue.length <= 2) return true;
    final raw = MyCharacter.removeChineseCharacters(state.totalValue[2].toString()).trim();
    if (raw.isEmpty || raw == '-' || raw == '0') return true;
    final count = int.tryParse(raw);
    return count == null || count <= 0;
  }

  void _saveLastRowRestartStatSnapshot(
    String snapshot, {
    required VoidCallback onDone,
    VoidCallback? onFail,
  }) {
    if (state.table2List.isEmpty) {
      onFail?.call();
      return;
    }
    if (snapshot.isEmpty) {
      onDone();
      return;
    }
    BXPut<dynamic>(
      Api.updateLastRowRestartStatSnapshot,
      isShowLoading: false,
      showError: false,
      params: {'restartStatSnapshot': snapshot},
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          if (state.table2List.isNotEmpty) {
            state.table2List.last.restartStatSnapshot = snapshot;
          }
          onDone();
        } else {
          BXLoading.showToast(message.isNotEmpty ? message : '保存重启快照失败');
          onFail?.call();
        }
      },
      failed: (_, __) => onFail?.call(),
    );
  }

  void _callRestartApi(String snapshot) {
    if (state.table2List.isEmpty) {
      Loading.dismiss();
      return;
    }
    BXPost<Table1Model>(
      Api.restart,
      isShowLoading: false,
      params: {"index": state.table2List.last.id},
      success: (isSuccess, code, message, value) {
        Loading.dismiss();
        if (isSuccess) {
          state.table1List = value;
          state.table2List = state.table2List.map((element) => element..colmunShuyingzhiD = "").toList();
          if (snapshot.isNotEmpty && state.table2List.isNotEmpty) {
            state.table2List.last.restartStatSnapshot = snapshot;
          }
          state.currentTempIndex = 0;
          _getStatisticalAreasData(-1);
          update();
        } else {
          BXLoading.showToast(message.isNotEmpty ? message : '重启失败');
        }
      },
      failed: (_, __) => Loading.dismiss(),
      onModel: (m) => Table1Model.fromJson(m),
    );
  }

  //重启局部数据
  void reStart() {
    Get.defaultDialog(
      barrierDismissible: false,
      backgroundColor: state.isDarkMode ? const Color(0xFF1E2A3A) : Colors.white,
      title: '警告',
      content: Text(
        '是否重启局部数据',
        style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
      ),
      titleStyle: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
      contentPadding: const EdgeInsets.all(20),
      onCancel: () {},
      onConfirm: () {
        Get.back();
        if (state.table2List.isEmpty) {
          BXLoading.showToast('暂无投注记录，无法重启');
          return;
        }
        if (_isRoundStatsEmpty()) {
          BXLoading.showToast('回合数据为空，无需重启');
          return;
        }
        Loading.show();
        final snapshot = _buildRestartStatSnapshot();
        if (snapshot.isNotEmpty) {
          state.table2List.last.restartStatSnapshot = snapshot;
          update();
        }
        _saveLastRowRestartStatSnapshot(
          snapshot,
          onDone: () => _callRestartApi(snapshot),
          onFail: Loading.dismiss,
        );
      },
    );
  }

  void updateBenJin(String b) {
    BXPost<Table1Model>(
      Api.updateBenjin,
      params: {"benjin": b},
      success: (isSuccess, code, message, value) {
        if (isSuccess) {
          BXLoading.showToast("${value.last.columnBenjin}");
          state.totalValue[0] = b;
          state.totalValue[4] = (double.parse(state.totalValue[0]) + double.parse(state.totalValue[17])).toString();
          _getStatisticalAreasData(-2);
        }
      },
      onModel: (m) => Table1Model.fromJson(m),
    );
  }

  void updateOdds(String b) {
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
        //改成接口，不用model接收值
        sort();
        break;
      case 1: //清除数据（消数列数据全部清除）
        int count = 0;
        for (var _ in state.table2List) {
          state.table2List[count].colmunShuyingzhiD = "";
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
        Get.defaultDialog(
          barrierDismissible: false,
          backgroundColor: state.isDarkMode ? const Color(0xFF1E2A3A) : Colors.white,
          title: '警告',
          content: Text(
            '是否删除全部数据',
            style: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
          ),
          titleStyle: TextStyle(color: state.isDarkMode ? Colors.white : Colors.black),
          contentPadding: const EdgeInsets.all(20),
          onCancel: () {},
          onConfirm: () {
            Loading.show();
            BXDelete(Api.deleteall, success: (isSuccess, code, message, results) {
              if (isSuccess) {
                BXLoading.showToast(message);
                state.table1List.clear();
                state.table2List.clear();
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
          params: {"resetIndex": (state.table2List.last.id)},
          success: (bool isSuccess, int code, String message, List<dynamic> results) {},
        );
        break;
      case 6: //备份数据
        Loading.show();
        BXPost(
          Api.backupManual,
          success: (isSuccess, code, message, results) {
            debugPrint('=====备份完成===== ${results.first}');
            Loading.dismiss();
            if (isSuccess) {
              Get.snackbar(
                '备份成功',
                '数据库备份已完成',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            } else {
              Get.snackbar(
                '备份失败',
                message,
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
          },
          failed: (error, model) {
            Loading.dismiss();
            Get.snackbar(
              '备份失败',
              '网络错误：$error',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          },
          isShowLoading: false, // 使用自定义的Loading
        );
        break;
      case 7:
        reStart();
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

  sort() {
    //改成接口，不用model接收值
    BXPost(Api.sortxiaoshu, success: (isSuccess, code, message, results) {
      if (isSuccess) {
        // BXLoading.showToast(message);
        var list = (results.first as Map<String, dynamic>)["sorted_sequence"];
        final n = state.table2List.length;
        final m = list.length;
        for (int i = 0; i < n; i++) {
          final idx = m - n + i;
          if (idx < 0 || idx >= m) {
            state.table2List[i].colmunShuyingzhiD = '';
            continue;
          }
          state.table2List[i].colmunShuyingzhiD = list[idx];
        }
        update();
      }
    });
  }

  void dropAll() {
    state.table2List.clear();
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
        // 修改期望值后，重新刷新统计区数据，保持界面数据和后台一致
        _getStatisticalAreasData(-2);
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
    _timer = Timer(Duration(seconds: 60 * state.LockScreenTime), () {
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

  /// 切换暗黑主题
  void toggleDarkMode() {
    state.isDarkMode = !state.isDarkMode;
    update();
  }

  /// 切换图表显示/隐藏
  void toggleChartVisibility() {
    state.isChartVisible = !state.isChartVisible;
    update();
  }

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

  //(取消)局部平衡
  juBuPingHeng(int index, {v}) {
    //-1 取消局部平衡
    if (index == -1) {
      if (state.currentTempIndex == 0) {
        return;
      }
      state.currentTempIndex = 0;
    } else {
      state.currentTempIndex = index;
    }
    update();
    if (state.table2List.isNotEmpty) _getStatisticalAreasData(index);
  }

  //统计区的下拉刷新
  Future<void> refreshStatsArea() async {
    state.isRefreshing = true;
    update();
    try {
      await _queryMysqlTable1();
      await _getStatisticalAreasData(-2);
      await _reloadBettingListTail();
    } catch (e) {
      debugPrint('统计区下拉刷新失败: $e');
    } finally {
      state.isRefreshing = false;
      update();
    }
  }

  //下拉刷新
  void onRefresh() {
    refreshStatsArea();
  }

  //加载更多
  void onLoadMore() {
    // id 为 null 时 Dio 会发出 last_id= 无值，后端会走错分支；空列表用 -1。
    // 与后端 LoadMore 一致：数据为 created_at 升序，分页游标为当前已加载中最旧一条（first）的 id。
    final anchorId = state.table2List.isEmpty ? -1 : (state.table2List.first.id ?? -1);
    BXGet<Table2Model>(Api.loadMore,
        params: {"last_id": anchorId, "uid": GetStore.getInstance().userModel.userId, "c": 250}, //"c"每页多少个数据
        success: (isSuccess, code, message, results) {
          if (!isSuccess) {
            refreshcontroller.finishRefresh(IndicatorResult.fail, true);
            return;
          }

          if (results.isEmpty) {
            refreshcontroller.finishRefresh(IndicatorResult.noMore, true);
            return;
          }

          if (results.isNotEmpty) {
            double? keptPixels;
            if (scrollController.hasClients) {
              keptPixels = scrollController.position.pixels;
            }
            state.table2List.insertAll(0, results);
            if (!state.isBigRoad) {
              _getLineCharts(applyStatsTail: true);
            }
            update();
            refreshcontroller.finishRefresh(IndicatorResult.success, true);
            if (keptPixels != null) {
              _schedulePreserveScrollAfterPrepend(keptPixels, results.length);
            }
          }
        },
        onModel: (m) => Table2Model.fromJson(m));
  }

  changeChart() {
    _reloadLuZiTu();
    state.isBigRoad = !state.isBigRoad;
    if (!state.isBigRoad) {
      _getLineCharts(applyStatsTail: true);
    }
    update();
    // 切到大路子图时组件本帧才挂上 Scrollable，须在 update 之后再调度一次滚动。
    if (state.isBigRoad) {
      _scheduleRoadMapScrollAfterRebuild();
    }
  }

  //重新加载路子图
  _reloadLuZiTu() {
    var list = state.table2List.map((e) => e.colmunShuyingzhi!.startsWith("-") ? "闲家" : "庄家").toList();
    state.initializeBigRoad();
    for (var value in list) {
      updateBigRoad(value);
    }
    _scheduleRoadMapScrollAfterRebuild();
  }
}
