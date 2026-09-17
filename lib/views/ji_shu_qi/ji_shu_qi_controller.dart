import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ycd/model/linechart_data_model.dart';
import 'package:ycd/model/user_model.dart';
import 'package:ycd/my_db/jsq_bet_record_model.dart';
import 'package:ycd/my_db/jsq_operation_record_model.dart';
import 'package:ycd/my_widget/more_functions_dialog.dart';
import 'package:ycd/my_widget/review_approved_dialog.dart';
import 'package:ycd/utils/bx_loading.dart';
import 'package:ycd/utils/day_night_theme.dart';
import 'package:ycd/utils/my_character.dart';
import 'package:ycd/utils/network/api.dart';
import 'package:ycd/utils/network/api_session_handler.dart';
import 'package:ycd/utils/network/get_store.dart';
import 'package:ycd/utils/network/http_mgr.dart';
import 'package:ycd/utils/storage_util.dart';

import 'ji_shu_qi_state.dart';

class JiShuQiController extends GetxController {
  /// 计数器页自动锁屏 PIN，任一可解锁（均须与 `correctString` 位数一致）
  static const List<String> _lockScreenPins = ['1111', '0000'];

  /// 统计区下拉刷新（与投注列表同款 EasyRefresh 样式，独立 controller）
  EasyRefreshController statsRefreshController =
      EasyRefreshController(controlFinishRefresh: true);
  final JiShuQiState state = JiShuQiState();

  final scrollController = ScrollController();

  /// 投注列表「眼睛」行 GlobalKey，用于精确定位滚动（避免手算行高累积误差）
  final GlobalKey tempIndexRowKey = GlobalKey();
  final textEditingController = TextEditingController();
  final focusNode = FocusNode();
  double _lastKeyboardInset = 0;
  Timer? _keyboardOpenSettleTimer;
  int _bettingListScrollGeneration = 0;
  bool _keepBettingListPinnedDuringKeyboard = false;
  bool _bettingListUserDragActive = false;
  bool _didRequestBettingHistoryDuringCurrentDrag = false;
  bool _isLoadingBettingHistory = false;
  bool _hasMoreBettingHistory = true;
  DateTime? _ignoreTapOutsideUntil;

  bool get isLoadingBettingHistory => _isLoadingBettingHistory;

// 定义一个计时器，用于延时锁屏
  Timer? _timer;

  /// 到点自动切换亮/暗色
  Timer? _dayNightThemeTimer;

  final ScrollController roadMapScrollController =
      ScrollController(); //路子图的controller
  final AudioPlayer _diceSoundPlayer = AudioPlayer();
  bool _diceSoundAvailable = true;
  double? _bettingInputPreviewBaseCurrentJin;
  OverlayEntry? _randomResultOverlayEntry;
  Timer? _randomResultOverlayTimer;

  /// 并发多次 [_getLineCharts] 时仅采纳最近一次发起的 `linechartData` 回调，避免旧响应把已画好的曲线冲掉。
  int _lineChartRequestGen = 0;

  @override
  void onInit() {
    super.onInit();
    _initDayNightTheme();
    WakelockPlus.enable();
    onUserInteraction();
    focusNode.addListener(_onInputFocusChanged);

    List.generate(32, (index) => state.totalValue.add('$index'));
    textEditingController.addListener(
      () {
        state.bettingMoney = textEditingController.text;
        _updateBettingInputCurrentJinPreview();
        if (textEditingController.text.isNotEmpty) {
          ///总体
          state.totalValue[20] = pVal1();

          ///局部
          state.totalValue[24] = pVal2();
        }
        update();
      },
    );
    scrollController.addListener(_onBettingListScroll);
    unawaited(_bootstrapPageData());
  }

  /// 进入页面：统一 Loading；并行请求关闭各自 Toast，由本方法汇总提示一次。
  Future<void> _bootstrapPageData() async {
    BXLoading.show();
    String? errorMsg;
    try {
      Future<void> track(Future<void> future) => future.catchError((e) {
            errorMsg ??= e is String ? e : e.toString();
          });

      await Future.wait([
        track(_queryOperationRecords(isShowLoading: false, showError: false)),
        track(_getStatisticalAreasData(JiShuQiState.tempIndexCmdInit,
            isShowLoading: false, showError: false)),
        track(_reloadBettingListTail(isShowLoading: false, showError: false)),
      ]);
    } finally {
      BXLoading.reset();
    }
    if (errorMsg != null && errorMsg!.isNotEmpty) {
      BXLoading.showToast(errorMsg!);
    }
    state.isInitialDataLoading = false;
    state.isCanPress = true;
    update();
  }

  void _onInputFocusChanged() {
    if (!focusNode.hasFocus) return;
    // 刚聚焦时短暂忽略 onTapOutside，避免 Android 弹出键盘瞬间误触收回。
    _ignoreTapOutsideUntil =
        DateTime.now().add(const Duration(milliseconds: 280));
  }

  bool get shouldIgnoreTapOutside {
    final until = _ignoreTapOutsideUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void onInputTapOutside() {
    if (shouldIgnoreTapOutside) return;
    guardAgainstKeyboardPop();
  }

  /// 按最新一页重新拉取投注记录（`last_id: -1`，与进入页面时一致）。
  /// [minCount] 至少条数；若已静默加载更多历史，则用当前条数避免刷新后列表变短。
  /// **局部平衡锚点 id 若不在本窗口内**：不扩列表、不特殊处理；该行不在 `betRecordList` 时眼睛不出现即可。
  Future<void> _reloadBettingListTail({
    int minCount = 66,
    bool isShowLoading = false,
    bool showError = true,
  }) async {
    final completer = Completer<void>();
    final n = state.betRecordList.length > minCount
        ? state.betRecordList.length
        : minCount;
    BXGet<JsqBetRecordModel>(
      Api.loadMore,
      params: {
        "last_id": -1,
        "uid": GetStore.getInstance().userModel.userId,
        "c": n
      },
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          if (results.isEmpty) {
            _hasMoreBettingHistory = false;
            state.betRecordList.clear();
            _reloadLuZiTu();
            update();
          } else {
            _hasMoreBettingHistory = true;
            state.betRecordList.clear();
            state.betRecordList = List<JsqBetRecordModel>.from(results);
            _reloadLuZiTu();
            update();
            scrollBettingListToBottom();
          }
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      failed: (message, _) {
        if (!completer.isCompleted) {
          completer.completeError(message);
        }
      },
      isShowLoading: isShowLoading,
      showError: showError,
      onModel: (m) => JsqBetRecordModel.fromJson(m),
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
      if ((state.currentRow < JiShuQiState.bigRoadRows &&
              state.bigRoad[state.currentRow][ids].isNotEmpty) ||
          state.currentRow > JiShuQiState.bigRoadRows - 1) {
        // 长龙处理：向右平移
        state.dragonStartCol++;
        state.bigRoad[state.dragonParallelRow][state.dragonStartCol] = winner;
        debugPrint(
            '🐉️（长龙处理）与上一局相同，记录在 [${state.dragonParallelRow}][${state.dragonStartCol}]');
      } else {
        // 没有超过6行，且下方没有内容，正常往下走
        state.bigRoad[state.currentRow][state.currentCol - 1] = winner;
        state.dragonParallelRow = state.currentRow; // 记录最后一次行
        state.dragonStartCol = state.currentCol - 1; // 记录最后一次列
        debugPrint(
            '🐉️ 与上一局相同，记录在 [${state.currentRow}][${state.currentCol - 1}]');
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
        double currentColRightEdge = (state.dragonStartCol == -1
                ? state.currentCol
                : state.dragonStartCol + 1) *
            JiShuQiState.cellWidth;

        double currentScrollOffset =
            roadMapScrollController.position.pixels /* 当前滚动位置（滑动了多少）*/;
        /* 当前滚动位置 + 可见区域尺寸 = 可见区域右边界 */
        double visibleRightEdge = currentScrollOffset +
            roadMapScrollController.position.viewportDimension /* 可见区域尺寸 */;

        // 只有当当前列的右边界超出可见区域右边界时才滚动
        if (currentColRightEdge > visibleRightEdge) {
          // 计算需要滚动的距离，让当前列刚好可见
          double scrollDistance =
              currentColRightEdge - visibleRightEdge + JiShuQiState.cellWidth;
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

  static const double _bettingListBottomThreshold = 1.5;
  static const double _bettingHistoryPrefetchExtent =
      JiShuQiState.bettingTableRowHeight * 8;

  bool _computeBettingListAtBottom() {
    if (!scrollController.hasClients) return state.isBettingListAtBottom;
    final pos = scrollController.position;
    final max = pos.maxScrollExtent;
    if (!max.isFinite) return state.isBettingListAtBottom;
    if (max <= 0.5) return true;
    return max - pos.pixels <= _bettingListBottomThreshold;
  }

  void _onBettingListScroll() {
    final atBottom = _computeBettingListAtBottom();
    if (atBottom != state.isBettingListAtBottom) {
      state.isBettingListAtBottom = atBottom;
      update();
    }
    if (_bettingListUserDragActive) {
      _maybeLoadBettingHistorySilently();
    }
  }

  void _maybeLoadBettingHistorySilently() {
    if (_isLoadingBettingHistory ||
        _didRequestBettingHistoryDuringCurrentDrag ||
        !_hasMoreBettingHistory ||
        state.betRecordList.isEmpty ||
        !scrollController.hasClients) {
      return;
    }
    final extentBefore = scrollController.position.extentBefore;
    if (!extentBefore.isFinite ||
        extentBefore > _bettingHistoryPrefetchExtent) {
      return;
    }
    _didRequestBettingHistoryDuringCurrentDrag = true;
    unawaited(_loadBettingHistorySilently());
  }

  Future<void> _loadBettingHistorySilently() async {
    if (_isLoadingBettingHistory || !_hasMoreBettingHistory) return;
    _isLoadingBettingHistory = true;
    update();
    try {
      await onLoadMore();
    } finally {
      _isLoadingBettingHistory = false;
      update();
    }
  }

  void _syncBettingListAtBottom({bool? atBottom}) {
    final next = atBottom ?? _computeBettingListAtBottom();
    if (next == state.isBettingListAtBottom) return;
    state.isBettingListAtBottom = next;
    update();
  }

  /// 右下角悬浮钮：在底部时向上滚到眼睛行，否则向下滚到列表最底。
  void onBettingListJumpFabTap() {
    dismissKeyboard();
    if (state.isBettingListAtBottom) {
      // 没有眼睛目标或列表尚未挂载时 jump 是 no-op，此时仍要保留收键盘后的粘底校正。
      if (scrollController.hasClients && state.currentTempIndex != 0) {
        _stopKeepingBettingListPinned();
      }
      jumpToCurrentTempIndexRow();
    } else {
      if (_lastKeyboardInset > 0) {
        _keepBettingListPinnedDuringKeyboard = true;
      }
      scrollBettingListToBottom();
    }
  }

  /// 投注列表时间升序（最新在底部）。多帧 + 延迟重试，避免刚 `update()` 后 extent 未算准、或未挂上 Scrollable。
  void scrollBettingListToBottom() {
    final generation = ++_bettingListScrollGeneration;
    bool isCurrentRequest() => generation == _bettingListScrollGeneration;

    void jumpToEnd() {
      if (!isCurrentRequest() || !scrollController.hasClients) return;
      final max = scrollController.position.maxScrollExtent;
      if (!max.isFinite || max < 0) return;
      scrollController.jumpTo(max);
    }

    /// 仍未挂上 Scrollable；或已与底部相差较大：再试。extent 尚为 0 但条数较多时视为未布局完。
    bool needsAnotherTry() {
      if (!isCurrentRequest()) return false;
      if (!scrollController.hasClients) return state.betRecordList.isNotEmpty;
      if (state.betRecordList.isEmpty) return false;
      final pos = scrollController.position;
      final max = pos.maxScrollExtent;
      if (!max.isFinite) return true;
      if (max <= 0.5) {
        return state.betRecordList.length > 8;
      }
      return max - pos.pixels > 1.5;
    }

    void scheduleFrames(int left) {
      if (left <= 0 || !isCurrentRequest()) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isCurrentRequest()) return;
        jumpToEnd();
        final more = needsAnotherTry() && left > 1;
        if (more) scheduleFrames(left - 1);
      });
    }

    void retryAfterDelay() {
      if (!isCurrentRequest()) return;
      jumpToEnd();
      if (isCurrentRequest()) {
        _syncBettingListAtBottom(atBottom: true);
      }
    }

    scheduleFrames(10);
    Future.delayed(const Duration(milliseconds: 50), retryAfterDelay);
    Future.delayed(const Duration(milliseconds: 180), retryAfterDelay);
    Future.delayed(const Duration(milliseconds: 420), retryAfterDelay);
  }

  /// 用户开始触摸列表/页面后，旧的自动滚动重试不得再抢占拖动手势。
  void cancelPendingBettingListAutoScroll() {
    _keyboardOpenSettleTimer?.cancel();
    _bettingListScrollGeneration++;
  }

  void _stopKeepingBettingListPinned() {
    _keepBettingListPinnedDuringKeyboard = false;
    cancelPendingBettingListAutoScroll();
  }

  /// 列表真实拖动会暂停旧的自动滚动，但在确认离开底部前仍保留键盘会话的粘底意图。
  void onBettingListUserDragStart() {
    _bettingListUserDragActive = true;
    _didRequestBettingHistoryDuringCurrentDrag = false;
    cancelPendingBettingListAutoScroll();
  }

  void onBettingListUserDragPositionChanged() {
    if (!_bettingListUserDragActive) return;
    _keepBettingListPinnedDuringKeyboard =
        _lastKeyboardInset > 0 && _computeBettingListAtBottom();
    cancelPendingBettingListAutoScroll();
    _maybeLoadBettingHistorySilently();
  }

  void onBettingListUserDragEnd() {
    if (!_bettingListUserDragActive) return;
    _maybeLoadBettingHistorySilently();
    _bettingListUserDragActive = false;
    _keepBettingListPinnedDuringKeyboard =
        _lastKeyboardInset > 0 && _computeBettingListAtBottom();
    cancelPendingBettingListAutoScroll();
  }

  /// 点击列表等空白区域时收起键盘（不用 TextField.onTapOutside，避免弹出瞬间误触收回）。
  void dismissKeyboard() {
    if (focusNode.hasFocus) {
      focusNode.unfocus(disposition: UnfocusDisposition.scope);
    }
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary.hasFocus) {
      primary.unfocus(disposition: UnfocusDisposition.scope);
    }
  }

  /// 底部键盘展开或输入框仍聚焦时释放焦点。
  /// 用于点骰子、关庄闲弹窗等场景，避免输入框再次被激活、键盘又顶起来。
  /// 若键盘本就没开，则不做任何事。
  void guardAgainstKeyboardPop() {
    if (!focusNode.hasFocus && _lastKeyboardInset <= 0) return;
    dismissKeyboard();
  }

  /// 键盘“弹出完成后”再滚到底，避免动画过程中触发布局抖动。
  void onKeyboardInsetChanged(double inset) {
    final previousInset = _lastKeyboardInset;
    if (previousInset == inset) return;

    _lastKeyboardInset = inset;

    // inset 动画本身不是用户滚动，不能让它取消刚由数据更新触发的滚底重试。
    _keyboardOpenSettleTimer?.cancel();
    if (inset > 0) {
      if (previousInset <= 0) {
        _keepBettingListPinnedDuringKeyboard = true;
      }
      // 键盘动画或键盘类型切换会连续上报 inset。每次变化都重新计时，
      // 确保使用稳定后的列表视口高度滚到底。
      _keyboardOpenSettleTimer = Timer(const Duration(milliseconds: 260), () {
        if (!focusNode.hasFocus ||
            _lastKeyboardInset <= 0 ||
            !_keepBettingListPinnedDuringKeyboard) {
          return;
        }
        scrollBettingListToBottom();
      });
    } else if (inset <= 0 && previousInset > 0) {
      final shouldRestoreBottom = _keepBettingListPinnedDuringKeyboard;
      _keepBettingListPinnedDuringKeyboard = false;
      if (!shouldRestoreBottom) {
        return;
      }

      // 键盘完全收起时图表与 SafeArea 会重新加入布局；等新 viewport 生效后再按新的 extent 滚底。
      final generation = _bettingListScrollGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (generation != _bettingListScrollGeneration ||
            _lastKeyboardInset > 0) {
          return;
        }
        scrollBettingListToBottom();
      });
    }
  }

  void jumpToCurrentTempIndexRow() {
    if (!scrollController.hasClients) return;
    final tempIndex = state.currentTempIndex;
    if (tempIndex == 0) return;

    int idx = state.betRecordList
        .indexWhere((e) => e.id != null && e.id == tempIndex);
    // 如果眼睛的位置不在列表中，则加载更多数据，再滚动到眼睛的位置
    if (idx < 0) {
      unawaited(_loadMoreForTempIndex(tempIndex));
      return;
    }
    _scrollToTempIndexRow(idx);
  }

  Future<void> _loadMoreForTempIndex(int tempIndex) async {
    if (state.betRecordList.isEmpty) return;
    final firstId = state.betRecordList.first.id;
    if (firstId == null) return;
    // 目标 id 比当前最旧 id 还新，说明不存在“往前加载更多”空间。
    if (tempIndex >= firstId) return;

    var loadCount = firstId - tempIndex;
    if (loadCount < 1) loadCount = 1;
    final inserted = await onLoadMore(
      count: loadCount,
      preserveViewport: false,
    );
    if (inserted <= 0) return;

    // 加载后按最新列表重算一次索引再滚动。
    await WidgetsBinding.instance.endOfFrame;
    if (!scrollController.hasClients) return;
    final idx = state.betRecordList
        .indexWhere((e) => e.id != null && e.id == tempIndex);
    if (idx >= 0) {
      _scrollToTempIndexRow(idx);
    }
  }

  /// 滚到「眼睛」行：优先 [Scrollable.ensureVisible]；行未挂载时用行高粗估再重试。
  void _scrollToTempIndexRow(int idx) {
    if (!scrollController.hasClients || idx < 0) return;
    const rowH = JiShuQiState.bettingTableRowHeight;

    Future<void> tryEnsure({int attempt = 0}) async {
      final ctx = tempIndexRowKey.currentContext;
      if (ctx != null) {
        final viewport = scrollController.position.viewportDimension;
        final align = viewport > 0
            ? (JiShuQiState.bettingTableScrollTopInset / viewport)
                .clamp(0.0, 0.35)
            : 0.0;
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: align,
        );
        return;
      }
      if (attempt > 15) return;
      final maxS = scrollController.position.maxScrollExtent;
      if (maxS.isFinite) {
        scrollController.jumpTo((idx * rowH).clamp(0.0, maxS));
      }
      await WidgetsBinding.instance.endOfFrame;
      await tryEnsure(attempt: attempt + 1);
    }

    unawaited(tryEnsure());
  }

  /// 顶部插入历史行后恢复视口：用固定行高累计增量，避免 LazyList 重新布局时视口跳动。
  /// 用户越界拖动时 [keptPixels] 可能为负，按 0 处理。
  void _schedulePreserveScrollAfterPrepend(
      double keptPixels, int insertedCount) {
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
    // 等待 LazyList 完成后续布局后再校正两次。
    Future.delayed(const Duration(milliseconds: 320), apply);
    Future.delayed(const Duration(milliseconds: 560), apply);
  }

  /// 局部平衡锚点（投注列表「眼睛」行 id）：以后端“jsq_operation_records.temp_index”为准，
  /// 对应客户端 `operationRecordList.last.tempIndex`；值为整数且 **>2** 视为有效 投注记录主键 id。
  /// **temp_index 为取消或重启指令**：`currentTempIndex` 固定为 **0**。
  /// 若无 操作记录数据则退回统计接口回填的 `totalValue[29]`（兼容冷启动顺序）。
  /// **锚点 id 不在当前 `betRecordList` 时**：不处理列表窗口（不保证眼睛可见）；仅保持 `currentTempIndex` 与配置一致。
  void _syncLocalTempIndexWithBackendState() {
    if (state.operationRecordList.isNotEmpty) {
      final raw = state.operationRecordList.last.tempIndex?.trim() ?? '';
      // 后端 temp_index 为清空指令：锚点归零
      if (_isClearLocalTempIndex(raw)) {
        state.currentTempIndex = 0;
        return;
      }
      final v = int.tryParse(raw);
      state.currentTempIndex = _isEffectiveLocalTempIndex(v) ? v! : 0;
      return;
    }
    if (state.totalValue.length > 29) {
      final raw = state.totalValue[29].toString().trim();
      if (raw.isEmpty) return;
      if (_isClearLocalTempIndex(raw)) {
        state.currentTempIndex = 0;
        return;
      }
      final v = int.tryParse(raw);
      if (_isEffectiveLocalTempIndex(v)) state.currentTempIndex = v!;
    }
  }

  bool _isClearLocalTempIndex(Object? tempIndex) =>
      tempIndex == JiShuQiState.tempIndexCmdCancel ||
      tempIndex == JiShuQiState.tempIndexCmdReset;

  bool _isEffectiveLocalTempIndex(Object? tempIndex) =>
      tempIndex is int && tempIndex > 2;

  void _applyTodayBetCountFromStatsPayload(dynamic payload) {
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);
    if (!map.containsKey('today_bet_count')) return;
    state.todayBetCount =
        int.tryParse(map['today_bet_count']?.toString() ?? '') ?? 0;
  }

  List<dynamic> _statisticalAreasFromResults(List<dynamic> results) {
    if (results.isEmpty) return results;
    final first = results.first;
    if (first is Map && first.containsKey('areas')) {
      _applyTodayBetCountFromStatsPayload(first);
      final areas = first['areas'];
      if (areas is List) return List<dynamic>.from(areas);
    }
    return results;
  }

  /// tempIndex 指令协议：
  /// - init：页面首次加载，恢复后端已保存的锚点。
  /// - keep：数据变化后刷新统计，但保留当前锚点。
  /// - cancel(取消)：用户主动取消局部平衡。
  /// - reset(重启)：重启局部数据后清空局部平衡锚点。
  /// - anchor(>2)：选中投注记录 id 作为局部平衡锚点。
  Future<void> _getStatisticalAreasData(
    Object? tempIndex, {
    bool isShowLoading = true,
    bool showError = true,
    bool skipLineChart = false,
  }) {
    final completer = Completer<void>();
    BXGet<dynamic>(
      Api.getStatisticalAreasData,
      params: {"tempIndex": tempIndex},
      isShowLoading: isShowLoading,
      showError: showError,
      success: (isSuccess, code, message, results) {
        final areas = _statisticalAreasFromResults(results);
        state.totalValue = areas.map((e) => e.toString()).toList();
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
          } else if (!skipLineChart) {
            _getLineCharts(applyStatsTail: true);
          } else {
            update();
          }
          _delayedTask(); //必须要提一个方法放出去，不然会会卡下面的代码
          if (!completer.isCompleted) {
            completer.complete();
          }
        }

        // 取消、重启或选中锚点行(>2) 时后端会更新 operationRecord.tempIndex；须先拉 operationRecord 再同步，
        // 否则会沿用内存里旧的 temp_index，把 currentTempIndex 又写回去（取消失效）。
        final ti = tempIndex;
        final needsFreshOperationRecords =
            _isClearLocalTempIndex(ti) || _isEffectiveLocalTempIndex(ti);
        if (needsFreshOperationRecords) {
          _queryOperationRecords()
              .then((_) => continueAfterStatsReady())
              .catchError((_) => continueAfterStatsReady());
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

  void showBottomFunction() {
    dismissKeyboard();
    Get.dialog<void>(
      MoreFunctionsDialog(
        isDarkMode: state.isDarkMode,
        functionTypes: state.functionTypes,
        onSelected: (index) => unawaited(functionConfirm(index)),
      ),
      barrierDismissible: true,
      barrierColor:
          Colors.black.withValues(alpha: state.isDarkMode ? 0.62 : 0.42),
      useSafeArea: true,
    );
  }

  double _commissionRate() {
    if (state.totalValue.length <= 31) return 0.95;
    final raw = state.totalValue[31].toString();
    if (raw.isEmpty || raw == '31') return 0.95;
    return double.tryParse(raw) ?? 0.95;
  }

  double? _parseStatDouble(dynamic raw) {
    final s = MyCharacter.removeChineseCharacters(raw.toString()).trim();
    if (s.isEmpty || s == '-') return null;
    return double.tryParse(s);
  }

  void _updateBettingInputCurrentJinPreview() {
    if (state.totalValue.length <= 4) return;
    final inputText = textEditingController.text.trim();
    if (inputText.isEmpty) {
      final base = _bettingInputPreviewBaseCurrentJin;
      if (base != null) {
        state.totalValue[4] = base.toStringAsFixed(2);
      }
      _bettingInputPreviewBaseCurrentJin = null;
      return;
    }

    final inputAmount = double.tryParse(inputText);
    if (inputAmount == null) return;

    _bettingInputPreviewBaseCurrentJin ??=
        _parseStatDouble(state.totalValue[4]);
    final base = _bettingInputPreviewBaseCurrentJin;
    if (base == null) return;
    state.totalValue[4] = (base - inputAmount).toStringAsFixed(2);
  }

  String pVal2() {
    if (state.bettingMoney.isEmpty || !state.bettingMoney.isNum) return '';
    final bet = double.tryParse(textEditingController.text);
    if (bet == null) return '';
    final val = state.randomValue == '庄'
        ? (bet * _commissionRate()).toStringAsFixed(2)
        : textEditingController.text;
    final x = _parseStatDouble(state.totalValue[18]); // 总盈利相关统计
    final y = double.tryParse(val); //输入框下注额
    final z = _parseStatDouble(state.totalValue[14]); //净胜
    if (x == null || y == null || z == null) return '';
    final z1 = z.abs(); //净胜绝对值
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
    final bet = double.tryParse(textEditingController.text);
    if (bet == null) return '';
    final val = state.randomValue == '庄'
        ? (bet * _commissionRate()).toStringAsFixed(2)
        : textEditingController.text;
    final x = _parseStatDouble(state.totalValue[17]); // 总盈利
    final y = double.tryParse(val); //输入框下注额
    final z = _parseStatDouble(state.totalValue[13]); //净胜
    if (x == null || y == null || z == null) return '';
    final z1 = z.abs(); //净胜绝对值
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
    cancelPendingBettingListAutoScroll();
    scrollController.removeListener(_onBettingListScroll);
    focusNode.removeListener(_onInputFocusChanged);
    _timer?.cancel();
    _dayNightThemeTimer?.cancel();
    _hideRandomResultOverlay();
    _diceSoundPlayer.dispose();
    statsRefreshController.dispose();
    WakelockPlus.disable();
    focusNode.dispose();
    textEditingController.dispose();
    super.onClose();
  }

  void _playSound(String asset, {double volume = 1.0}) {
    if (!_diceSoundAvailable) return;
    unawaited(() async {
      try {
        await _diceSoundPlayer.stop();
        await _diceSoundPlayer.play(
          AssetSource(asset),
          volume: volume,
          mode: PlayerMode.lowLatency,
        );
      } catch (e) {
        _diceSoundAvailable = false;
        debugPrint('sound unavailable: $e');
      }
    }());
  }

  void _randomFeedback() => unawaited(HapticFeedback.lightImpact());

  void _playRandomSound() => _playSound('sounds/random_ding.wav', volume: 0.4);

  void _playDiceRollSound() => _playSound('sounds/zhuotou.mp3');

  void _hideRandomResultOverlay() {
    _randomResultOverlayTimer?.cancel();
    _randomResultOverlayTimer = null;
    _randomResultOverlayEntry?.remove();
    _randomResultOverlayEntry = null;
  }

  void _showRandomResultOverlay(String title) {
    _hideRandomResultOverlay();
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _randomResultOverlayEntry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.18),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 90,
                color: state.isDarkMode ? state.darkTextColor : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_randomResultOverlayEntry!);
    _randomResultOverlayTimer =
        Timer(const Duration(milliseconds: 500), _hideRandomResultOverlay);
  }

  setRandom(Function(int) f) {
    if (!state.isCanPress) {
      return;
    }
    _randomFeedback();
    _playRandomSound();
    state.isCanPress = false;
    state.js2 = state.js2 + 1;
    state.totalValue[28] = "${state.js1}/${state.js2}";
    BXGet(
      Api.randomBankerPlayer,
      success: (isSuccess, code, message, results) {
        if (!isSuccess || results.isEmpty) {
          _rollbackRandomPress();
          return;
        }
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
        _showRandomResultOverlay(state.randomValue);
        state.isCanPress = true;

        ///总体
        state.totalValue[20] = pVal1();

        ///局部
        state.totalValue[24] = pVal2();
        update();
      },
      failed: (_, __) => _rollbackRandomPress(),
      isShowLoading: false, // 使用自定义的Loading
    );
  }

  void _rollbackRandomPress() {
    if (state.js2 > 0) state.js2 = state.js2 - 1;
    state.totalValue[28] = "${state.js1}/${state.js2}";
    state.isCanPress = true;
    update();
  }

  _next(int min, int max) => min + Random().nextInt(max - min + 1);

  /// 服务端按 id 降序只返回当前有效配置；本地列表最多保留 1 条。
  void _applyOperationRecordsFromServer(List<JsqOperationRecordModel> fetched) {
    if (fetched.isEmpty) {
      state.operationRecordList = [];
      return;
    }
    state.operationRecordList = [fetched.last];
  }

  Future<void> _queryOperationRecords({
    bool isShowLoading = false,
    bool showError = true,
  }) {
    final completer = Completer<void>();
    BXGet<JsqOperationRecordModel>(Api.getOperationRecords,
        isShowLoading: isShowLoading,
        showError: showError,
        success: (isSuccess, code, message, value) {
          _applyOperationRecordsFromServer(value);
          if (state.operationRecordList.isNotEmpty) {
            state.totalValue[0] =
                '${state.operationRecordList.last.benjin}'; //本金
            state.totalValue[19] =
                '${state.operationRecordList.last.mean}'; //期望值
            // 折线形状必须由 [_getLineCharts]（投注记录末尾或 linechartData）提供；此处若用本金铺满 75 点，
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
          state.isCanPress = true;
          if (!completer.isCompleted) {
            completer.completeError(p0);
          }
        },
        onModel: (m) => JsqOperationRecordModel.fromJson(m));
    return completer.future;
  }

  betRecordButton(int i, String recordType,
      {JsqOperationRecordModel? operationRecord,
      JsqBetRecordModel? betRecord}) {
    if (state.randomValue.isEmpty) {
      Get.snackbar("温馨提示", '请摇塞子',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.2));
      return;
    }

    if (state.bettingMoney.isEmpty) {
      Get.snackbar("温馨提示", '请输入下注金额',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.3));
      return;
    }
    if (!state.bettingMoney.isNum) {
      Get.snackbar("温馨提示", '请输入数字',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.3));
      return;
    }
    if (!state.isCanPress) {
      Get.snackbar("温馨提示", '速度太快',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.white.withValues(alpha: 0.3));
      return;
    }
    _playDiceRollSound();
    BXLoading.show(douyinStyle: true);
    state.isCanPress = false;
    state.js1 = state.js1 + 1;
    final table = recordType == 'betRecord'
        ? JsqBetRecordModel(
            id: state.betRecordList.length + 1,
            xiazhujine: double.tryParse(state.bettingMoney),
            zx: (i == 2 || i == 3) ? '庄' : '闲',
            remark: (i == 1 || i == 2) ? "1" : "-1",
            shengfulu: ((i == 1 || i == 3) && (state.randomValue == '闲')) ||
                    ((i == 2 || i == 4) && (state.randomValue == '庄'))
                ? "正打"
                : "反打",
            shuyingzhi: syzLAmount(i),
            shuyingzhiXiaoshu: syzLAmount(i),
            currentJin: getCurrentJin(i, double.parse(state.bettingMoney)),
          )
        : JsqOperationRecordModel(
            benjin: 10000,
            yongjin: 0.95,
            mean: 0.08,
            restartIndex: null,
            liushuiIndex: null);

    ///改变成插入远程数据库
    if (recordType == 'operationRecord') {
      BXPut<JsqOperationRecordModel>(Api.createOperationRecord,
          params: (table as JsqOperationRecordModel).toJson()
            ..addAll({
              "user_id": int.parse(GetStore.getInstance().userModel.userId)
            }),
          isShowLoading: false,
          success: (isSuccess, code, message, results) {
            BXLoading.dismiss();
            state.isCanPress = true;
            if (isSuccess) BXLoading.showToast("操作记录");
          },
          failed: (p0, p1) {
            state.isCanPress = true;
            BXLoading.dismiss();
          },
          onModel: (m) => JsqOperationRecordModel.fromJson(m));
    } else {
      BXPut<JsqBetRecordModel>(Api.createBetRecord,
          isShowLoading: false,
          params: (table as JsqBetRecordModel).toJson()
            ..remove("betRecordId")
            ..addAll({
              "user_id": int.parse(GetStore.getInstance().userModel.userId)
            }),
          success: (isSuccess, code, message, results) {
            if (results.isNotEmpty) {
              final row = results.first;
              row.seq = state.betRecordList.isEmpty
                  ? 1
                  : (state.betRecordList.last.seq ??
                          state.betRecordList.length) +
                      1;
              state.betRecordList.add(row);
            }
            update(); // 先让 ListView 用新 itemCount 布局，再滚到底才准
            scrollBettingListToBottom();
            _getStatisticalAreasData(JiShuQiState.tempIndexCmdKeep,
                    isShowLoading: false)
                .whenComplete(BXLoading.dismiss);
          },
          failed: (p0, p1) {
            state.isCanPress = true;
            BXLoading.dismiss();
          },
          onModel: (m) => JsqBetRecordModel.fromJson(m));
    }
  }

  /// 折线 75 点一律走服务端：当前本金 + 累计 shuyingzhi（改本金后整体平移，不读库内 current_jin）。
  void _resetChartPad(double pad) {
    if (state.chartData.length != 75) {
      state.chartData =
          List.generate(75, (index) => LineChartDataModel(index, pad));
    } else {
      for (var i = 0; i < 75; i++) {
        state.chartData[i].sales = pad;
      }
    }
  }

  void _applyLineChartSeries(List<dynamic> results,
      {bool applyStatsTail = false}) {
    final benjin = state.operationRecordList.isNotEmpty
        ? double.tryParse(state.operationRecordList.last.benjin.toString())
        : null;
    final pad =
        benjin ?? (state.chartData.isNotEmpty ? state.chartData[0].sales : 0.0);
    _resetChartPad(pad);
    var z = 0;
    for (var i = results.length - 1;
        i >= 0 && z < state.chartData.length;
        i--) {
      final cell = results[i].toString().trim();
      if (cell.isNotEmpty) {
        state.chartData[z].sales = double.parse(cell);
      } else {
        state.chartData[z].sales = pad;
      }
      z++;
    }
    if (applyStatsTail) {
      _syncChartLastPointWithTotalValue();
    }
  }

  void _getLineCharts({bool applyStatsTail = false}) {
    final gen = ++_lineChartRequestGen;
    final benjin = state.operationRecordList.isNotEmpty
        ? double.tryParse(state.operationRecordList.last.benjin.toString())
        : null;
    final pad =
        benjin ?? (state.chartData.isNotEmpty ? state.chartData[0].sales : 0.0);
    _resetChartPad(pad);

    BXGet<dynamic>(
      Api.getLinechartData,
      success: (isSuccess, code, message, results) {
        if (gen != _lineChartRequestGen) return;
        if (!isSuccess) return;
        _applyLineChartSeries(results, applyStatsTail: applyStatsTail);
        update();
      },
      isShowLoading: false,
    );
  }

  /// 与统计区 [totalValue[4]] 对齐折线最右端（第 75 点），对应服务端「本金 + 全表输赢累计」。
  void _syncChartLastPointWithTotalValue() {
    if (state.chartData.length != 75) return;
    if (state.totalValue.length <= 4) return;
    final raw =
        MyCharacter.removeChineseCharacters(state.totalValue[4].toString())
            .trim();
    if (raw.isEmpty) return;
    final v = double.tryParse(raw);
    if (v != null) {
      state.chartData[74].sales = v;
    }
  }

  getCurrentJin(int i, double playMoney) {
    var lastJinE = state.betRecordList.isEmpty
        ? 5000
        : double.parse(state.totalValue[4].toString());
    switch (i) {
      case 1:
        return (lastJinE + playMoney);
      case 2:
        return (lastJinE) +
            playMoney *
                double.parse(
                    state.totalValue[31] == "31" || state.totalValue[31] == ""
                        ? "0.95"
                        : state.totalValue[31]);
      case 3:
      case 4:
        return (lastJinE) - playMoney;
    }
  }

  double? syzLAmount(int i) {
    final bet = double.tryParse(state.bettingMoney);
    if (bet == null) return null;
    switch (i) {
      case 1:
        return bet;
      case 2:
        final odds = double.tryParse(
                state.totalValue[31] == "31" || state.totalValue[31] == ""
                    ? "0.95"
                    : state.totalValue[31]) ??
            0.95;
        return bet * odds;
      case 3:
      case 4:
        return -bet;
      default:
        return null;
    }
  }

  /// 输赢展示字符串（带 +/- 前缀，仅用于界面）
  String syzL(int i) {
    final amount = syzLAmount(i);
    if (amount == null) return '';
    if (amount > 0) {
      return amount == double.parse(state.bettingMoney) && i == 1
          ? '+${state.bettingMoney}'
          : '+${_formatZhuangYingShuying(amount)}';
    }
    return '-${state.bettingMoney}';
  }

  /// 庄赢输赢字符串：去掉末尾多余 0，避免 0.095 被格式化成与 0.1 混淆。
  String _formatZhuangYingShuying(double value) {
    final s = value.toStringAsFixed(8); //四舍五入到8位小数
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void confirmDeleteLast() {
    dismissKeyboard();
    if (state.betRecordList.isEmpty) {
      BXLoading.showToast('暂无投注记录');
      return;
    }
    Get.dialog<void>(
      ReviewApprovedDialog(
        title: '警告',
        message: '是否返回上一步',
        badgeText: '将撤销最后一条投注记录',
        buttonText: '确定',
        secondaryButtonText: '取消',
        statusIcon: Icons.undo_rounded,
        isDarkMode: state.isDarkMode,
        onConfirmed: deleteLast,
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(
        alpha: state.isDarkMode ? 0.62 : 0.50,
      ),
    );
  }

  void deleteLast() {
    dismissKeyboard();
    if (state.betRecordList.isEmpty) return;
    BXDelete<JsqBetRecordModel>(Api.deleteLast,
        success: (isSuccess, code, message, results) {
          if (!isSuccess) return;
          if (results.isNotEmpty) {
            final deletedId = results.first.id;
            final idx = deletedId == null
                ? -1
                : state.betRecordList.indexWhere((e) => e.id == deletedId);
            if (idx >= 0) {
              state.betRecordList.removeAt(idx);
            } else if (state.betRecordList.isNotEmpty) {
              state.betRecordList.removeLast();
            }
          }
          state.js1 = state.js1 - 1;
          state.totalValue[28] = "${state.js1}/${state.js2}";
          _getStatisticalAreasData(JiShuQiState.tempIndexCmdKeep,
              isShowLoading: false);
          _reloadLuZiTu();
          update();
        },
        failed: (_, __) {},
        onModel: (m) => JsqBetRecordModel.fromJson(m));
  }

  void updateLists(int index) {
    dismissKeyboard();
    BXLoading.show();
    BXPost(
      Api.xiaoShu,
      isShowLoading: false,
      params: state.betRecordList[index].toJson()
        ..update("shuyingzhi_xiaoshu", (value) => null),
      success: (isSuccess, code, message, results) {
        if (isSuccess) {
          state.betRecordList[index].shuyingzhiXiaoshu = null;
          Future.delayed(const Duration(milliseconds: 500), () {
            BXLoading.dismiss();
            update();
          });
        } else {
          BXLoading.dismiss();
        }
      },
      failed: (_, __) => BXLoading.dismiss(),
    );
  }

  /// 重启前从统计区取 2/6/14/18 拼接快照（须在调用 restart 接口之前），
  /// 其中 index 18 四舍五入保留 1 位小数。
  String _buildRestartStatSnapshot() {
    const indices = [2, 6, 14, 18];
    return indices.map((i) {
      if (i >= state.totalValue.length) return '';
      final raw =
          MyCharacter.removeChineseCharacters(state.totalValue[i].toString())
              .trim();
      if (i != 18) return raw;
      final v = double.tryParse(raw);
      return v == null ? raw : v.toStringAsFixed(1);
    }).join('/');
  }

  /// 当前回合是否无数据（看统计区「回合局数」totalValue[2]）
  bool _isRoundStatsEmpty() {
    if (state.totalValue.length <= 2) return true;
    final raw =
        MyCharacter.removeChineseCharacters(state.totalValue[2].toString())
            .trim();
    if (raw.isEmpty || raw == '-' || raw == '0') return true;
    final count = int.tryParse(raw);
    return count == null || count <= 0;
  }

  void _saveLastRowRestartStatSnapshot(
    String snapshot, {
    required VoidCallback onDone,
    VoidCallback? onFail,
  }) {
    if (state.betRecordList.isEmpty) {
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
          if (state.betRecordList.isNotEmpty) {
            state.betRecordList.last.restartStatSnapshot = snapshot;
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
    if (state.betRecordList.isEmpty) {
      BXLoading.dismiss();
      return;
    }
    BXPost<JsqOperationRecordModel>(
      Api.restart,
      isShowLoading: false,
      params: {"index": state.betRecordList.last.id},
      success: (isSuccess, code, message, value) {
        BXLoading.dismiss();
        if (isSuccess) {
          _applyOperationRecordsFromServer(value);
          state.betRecordList = state.betRecordList
              .map((element) => element..shuyingzhiXiaoshu = null)
              .toList();
          if (snapshot.isNotEmpty && state.betRecordList.isNotEmpty) {
            state.betRecordList.last.restartStatSnapshot = snapshot;
          }
          state.currentTempIndex = 0;
          _getStatisticalAreasData(JiShuQiState.tempIndexCmdReset);
          update();
        } else {
          BXLoading.showToast(message.isNotEmpty ? message : '重启失败');
        }
      },
      failed: (_, __) => BXLoading.dismiss(),
      onModel: (m) => JsqOperationRecordModel.fromJson(m),
    );
  }

  int get todayBetGoalEffective =>
      GetStore.getInstance().userModel.effectiveDailyBetGoal;

  double get todayBetProgressFraction {
    final goal = todayBetGoalEffective;
    if (goal <= 0) return 0;
    return (state.todayBetCount / goal).clamp(0.0, 1.0);
  }

  /// 顶栏进度条右侧（如 `4/100`）
  String get todayBetProgressCountLabel {
    final goal = todayBetGoalEffective;
    return '${state.todayBetCount}/$goal';
  }

  /// 顶栏进度条刻度处显示（如 `4%`）
  String get todayBetProgressPercentLabel {
    final goal = todayBetGoalEffective;
    if (goal <= 0) return '0%';
    final pct = (state.todayBetCount * 100 / goal).round().clamp(0, 999);
    return '$pct%';
  }

  String get todayBetProgressLabel {
    final goal = todayBetGoalEffective;
    final count = state.todayBetCount;
    if (goal <= 0) return '今日目标 $count';
    final pct = (count * 100 / goal).clamp(0, 999).toStringAsFixed(0);
    return '今日目标 $count/$goal ($pct%)';
  }

  void showDailyBetGoalEditor() {
    dismissKeyboard();
    final store = GetStore.getInstance();
    Get.dialog<void>(
      ReviewInputDialog(
        title: '每日目标',
        message: '设置每天计划完成的下注次数',
        badgeText: '当前完成：$todayBetProgressLabel',
        hintText: '留空则使用默认 ${UserModel.defaultDailyBetGoal}',
        initialValue: store.userModel.dailyBetGoal?.toString() ?? '',
        statusIcon: Icons.flag_outlined,
        isDarkMode: state.isDarkMode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (raw) {
          if (raw.isEmpty) return null;
          final goal = int.tryParse(raw);
          return goal == null || goal < 1 ? '请输入 1 以上的整数' : null;
        },
        onSubmitted: (raw) =>
            _saveDailyBetGoal(raw.isEmpty ? null : int.parse(raw)),
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(
        alpha: state.isDarkMode ? 0.62 : 0.42,
      ),
    );
  }

  void _saveDailyBetGoal(int? goal) {
    BXPost<dynamic>(
      Api.updateDailyBetGoal,
      params: {'daily_bet_goal': goal},
      isShowLoading: true,
      success: (isSuccess, _, message, results) {
        if (!isSuccess) return;
        final store = GetStore.getInstance();
        final user = store.userModel;
        user.dailyBetGoal = goal;
        if (results.isNotEmpty && results.first is Map) {
          final row = Map<String, dynamic>.from(results.first as Map);
          if (row['daily_bet_goal'] == null) {
            user.dailyBetGoal = null;
          } else {
            user.dailyBetGoal = int.tryParse(row['daily_bet_goal'].toString());
          }
        }
        store.saveUser(user);
        update();
        BXLoading.showToast(message.isNotEmpty ? message : '每日目标已更新');
      },
      onModel: (m) => m,
    );
  }

  //重启局部数据
  void reStart() {
    Get.dialog<void>(
      ReviewApprovedDialog(
        title: '警告',
        message: '是否重启局部数据',
        badgeText: '重启后局部统计将重新计算',
        buttonText: '确定',
        secondaryButtonText: '取消',
        useRestartArtwork: true,
        isDarkMode: state.isDarkMode,
        onConfirmed: () {
          if (state.betRecordList.isEmpty) {
            BXLoading.showToast('暂无投注记录，无法重启');
            return;
          }
          if (_isRoundStatsEmpty()) {
            BXLoading.showToast('回合数据为空，无需重启');
            return;
          }
          BXLoading.show(douyinStyle: true);
          final snapshot = _buildRestartStatSnapshot();
          if (snapshot.isNotEmpty) {
            state.betRecordList.last.restartStatSnapshot = snapshot;
            update();
          }
          _saveLastRowRestartStatSnapshot(
            snapshot,
            onDone: () => _callRestartApi(snapshot),
            onFail: BXLoading.dismiss,
          );
        },
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(
        alpha: state.isDarkMode ? 0.62 : 0.50,
      ),
    );
  }

  void updateBenJin(String b) {
    BXPost<JsqOperationRecordModel>(
      Api.updateBenjin,
      params: {"benjin": b},
      isShowLoading: false,
      success: (isSuccess, code, message, value) {
        BXLoading.dismiss();
        if (isSuccess && value.isNotEmpty) {
          final row = value.last;
          BXLoading.showToast("${row.benjin}");
          final parsedBenjin = double.tryParse(b) ?? row.benjin;
          if (state.operationRecordList.isNotEmpty && parsedBenjin != null) {
            state.operationRecordList.last.benjin = parsedBenjin;
          }
          state.totalValue[0] = b;
          state.totalValue[4] = (double.parse(state.totalValue[0]) +
                  double.parse(state.totalValue[17]))
              .toString();
          final chart = row.lineChart;
          final hasServerChart = chart != null && chart.isNotEmpty;
          if (hasServerChart && !state.isBigRoad) {
            _applyLineChartSeries(chart, applyStatsTail: true);
            update();
          }
          _getStatisticalAreasData(
            JiShuQiState.tempIndexCmdKeep,
            skipLineChart: hasServerChart && !state.isBigRoad,
          );
        }
      },
      failed: (_, __) => BXLoading.dismiss(),
      onModel: (m) => JsqOperationRecordModel.fromJson(m),
    );
  }

  void reconcileBenJinByCurrentAmount(String currentAmountText) {
    BXLoading.show(douyinStyle: true);
    if (currentAmountText.isEmpty) {
      BXLoading.dismiss();
      BXLoading.showToast('请输入桌面金额 ${textEditingController.text} ');
      return;
    }
    final currentAmount = double.tryParse(currentAmountText);
    if (currentAmount == null) {
      BXLoading.dismiss();
      BXLoading.showToast('请输入数字 ${textEditingController.text} ');
      return;
    }
    final totalWin = state.totalValue.length > 17
        ? _parseStatDouble(state.totalValue[17])
        : null;
    if (totalWin == null) {
      BXLoading.dismiss();
      BXLoading.showToast('无法获取总盈利');
      return;
    }

    final newBenJin = currentAmount - totalWin;
    updateBenJin(newBenJin.toStringAsFixed(2));
  }

  void showCurrentAmountReconcileDialog() {
    dismissKeyboard();
    textEditingController.clear();

    final totalWin = state.totalValue.length > 17
        ? _parseStatDouble(state.totalValue[17])
        : null;
    Get.dialog<void>(
      ReviewInputDialog(
        title: '核对桌面金额',
        message: '输入桌面现有金额，自动反算并修改本金',
        badgeText: totalWin == null
            ? '无法获取总盈利'
            : '本金 = 桌面金额 - 总盈利(${totalWin.toStringAsFixed(2)})',
        hintText: '请输入桌面金额',
        buttonText: '确认修改',
        statusIcon: Icons.fact_check_outlined,
        isDarkMode: state.isDarkMode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        validator: (raw) {
          if (raw.isEmpty) return '请输入桌面金额';
          if (double.tryParse(raw) == null) return '请输入正确的数字';
          if (totalWin == null) return '无法获取总盈利';
          return null;
        },
        onSubmitted: reconcileBenJinByCurrentAmount,
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(
        alpha: state.isDarkMode ? 0.62 : 0.42,
      ),
    );
  }

  void updateOdds(String b) {
    BXPost/*<Map<String,dynamic>>*/(Api.updateOdds,
        params: {"odds": b},
        isShowLoading: false,
        success: (isSuccess, int code, String message, List<dynamic> results) {
          BXLoading.dismiss();
          if (isSuccess) {
            BXLoading.showToast(message);
            debugPrint("赔率值是=${(results[0]["odds"])}");
            state.totalValue[31] = (results[0]["odds"]).toString();
            _getStatisticalAreasData(JiShuQiState
                .tempIndexCmdKeep); //和recordButton里面传一样的参数，确保不会破坏局部平衡
          }
        },
        failed: (_, __) => BXLoading.dismiss());
  }

  //底部选项
  Future<void> functionConfirm(int i) async {
    var s = textEditingController.text.toString();
    switch (i) {
      case 0: //排列数据
        sort();
        break;
      case 1: //清除数据（消数列数据全部清除）
        int count = 0;
        for (var _ in state.betRecordList) {
          state.betRecordList[count].shuyingzhiXiaoshu = null;
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
        BXLoading.show(douyinStyle: true);
        if (s.isEmpty) {
          BXLoading.dismiss();
          BXLoading.showToast('请输入金额 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          BXLoading.dismiss();
          BXLoading.showToast('请输入数字 ${textEditingController.text} ');
          break;
        }
        updateBenJin(s);
        break;
      case 3: //修改位置
        BXLoading.show(douyinStyle: true);
        state.js2 = state.js1;
        state.totalValue[28] = "${state.js1}/${state.js2}";
        BXLoading.dismiss();
        break;
      case 4: //删除全部数据（当前用户下）
        Get.dialog<void>(
          ReviewApprovedDialog(
            title: '警告',
            message: '是否删除全部数据',
            badgeText: '删除后无法恢复，请谨慎操作',
            buttonText: '删除',
            secondaryButtonText: '取消',
            statusIcon: Icons.delete_outline_rounded,
            isDarkMode: state.isDarkMode,
            onConfirmed: () {
              BXDelete(Api.deleteAll,
                  success: (isSuccess, code, message, results) {
                if (isSuccess) {
                  BXLoading.showToast(message);
                  state.operationRecordList.clear();
                  state.betRecordList.clear();
                  state.randomValue = '';
                  List.generate(32,
                      (index) => state.totalValue[index] = index.toString());
                  _getStatisticalAreasData(JiShuQiState.tempIndexCmdReset,
                      isShowLoading: false);
                }
              });
            },
          ),
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(
            alpha: state.isDarkMode ? 0.62 : 0.50,
          ),
        );
        break;
      case 5: //重置流水
        if (state.betRecordList.isEmpty) {
          BXLoading.showToast('暂无投注记录');
          break;
        }
        final resetBetId = state.betRecordList.last.id;
        if (resetBetId == null) {
          BXLoading.showToast('无法获取最后一条记录');
          break;
        }
        BXPost<JsqOperationRecordModel>(
          Api.resetLiuShui,
          params: {"resetIndex": resetBetId},
          success: (bool isSuccess, int code, String message,
              List<JsqOperationRecordModel> results) {
            if (!isSuccess) return;
            BXLoading.showToast(message.isNotEmpty ? message : '重置流水成功');
            if (results.isNotEmpty) {
              final latest = results.last;
              if (state.operationRecordList.isNotEmpty) {
                state.operationRecordList.last.liushuiIndex =
                    latest.liushuiIndex;
              }
            }
            _getStatisticalAreasData(JiShuQiState.tempIndexCmdKeep,
                isShowLoading: false);
          },
          onModel: (m) => JsqOperationRecordModel.fromJson(m),
        );
        break;
      case 6: //备份数据
        BXLoading.show(douyinStyle: true);
        BXPost(
          Api.backupManual,
          isShowLoading: false,
          success: (isSuccess, code, message, results) {
            debugPrint('=====备份完成===== ${results.first}');
            BXLoading.dismiss();
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
            BXLoading.dismiss();
            Get.snackbar(
              '备份失败',
              '网络错误：$error',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          },
        );
        break;
      case 7: //返回上步
        confirmDeleteLast();
        break;
      case 8: //修改期望值
        if (s.isEmpty) {
          BXLoading.showToast('请输入期望值 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          BXLoading.showToast('请输入数字 ${textEditingController.text} ');
          break;
        }
        updateQiWangZhi(s);
        break;
      case 9: //修改赔率
        BXLoading.show(douyinStyle: true);
        if (s.isEmpty) {
          BXLoading.dismiss();
          BXLoading.showToast('请输入赔率 ${textEditingController.text} ');
          break;
        }
        if (!s.isNum) {
          BXLoading.dismiss();
          BXLoading.showToast('请输入赔率 ${textEditingController.text} ');
          break;
        }
        updateOdds(s);
        break;
      case 10: //退出程序
        await GetStore.getInstance().logout();
        ApiSessionHandler.goLogin(clearStack: false);
        break;
      case 11: //隐藏/显示序号
        state.isSeqVisible = !state.isSeqVisible;
        state.selectIndex = 11;
        update();
        break;
      case 12: //红输绿赢 / 红赢绿输
        state.isRedWinGreenLose = !state.isRedWinGreenLose;
        state.selectIndex = 12;
        update();
        break;
      case 13: //按时间自动亮/暗主题
        toggleThemeFollowsTime();
        break;
    }
  }

  sort() {
    dismissKeyboard();
    BXLoading.show(douyinStyle: true);
    BXPost(
      Api.sortXiaoShu,
      isShowLoading: false,
      success: (isSuccess, code, message, results) {
        BXLoading.dismiss();
        if (isSuccess) {
          var list = (results.first as Map<String, dynamic>)["sorted_sequence"];
          final n = state.betRecordList.length;
          final m = list.length;
          for (int i = 0; i < n; i++) {
            final idx = m - n + i;
            if (idx < 0 || idx >= m) {
              state.betRecordList[i].shuyingzhiXiaoshu = null;
              continue;
            }
            state.betRecordList[i].shuyingzhiXiaoshu =
                double.tryParse(list[idx].toString());
          }
          update();
        }
      },
      failed: (_, __) => BXLoading.dismiss(),
    );
  }

  void updateQiWangZhi(String qiwangzhi) {
    BXPost/*<Map<String,dynamic>>*/(Api.updateQiWangValue,
        params: {"mean": qiwangzhi}, isShowLoading: false,
        success: (isSuccess, int code, String message, List<dynamic> results) {
      if (isSuccess) {
        BXLoading.showToast(message);
        debugPrint("期望值是=${(results[0]["mean"])}");
        state.totalValue[19] = (results[0]["mean"]).toString();
        // 修改期望值后，重新刷新统计区数据，保持界面数据和后台一致
        _getStatisticalAreasData(JiShuQiState.tempIndexCmdKeep);
      }
    });
  }

  lockScreen() {
    _timer?.cancel();
    _timer = null;
    final context = Get.context;
    if (context == null) return;
    screenLock(
      useBlur: false,
      config: const ScreenLockConfig(
        backgroundColor: Colors.black,
      ),
      keyPadConfig: KeyPadConfig(
        buttonConfig: KeyPadButtonConfig(
          foregroundColor: Colors.white,
          buttonStyle: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white54,
            backgroundColor: Colors.transparent,
            side: const BorderSide(color: Colors.white38),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
        ),
        // 左下占位、右下删除键：无边框，避免左下空圈
        actionButtonConfig: KeyPadButtonConfig(
          foregroundColor: Colors.white,
          fontSize: 18,
          buttonStyle: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
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
      context: context,
      // 有 onValidate 时插件只用回调校验，correctString 仅决定输入位数
      correctString: _lockScreenPins.first,
      onValidate: (input) async => _lockScreenPins.contains(input),
      canCancel: false,
      //是否可以取消
      onUnlocked: () {
        Navigator.of(context, rootNavigator: true).pop();
        onUserInteraction();
      },
      onError: (_) {
        BXLoading.showToastOnDarkBackground('密码错误');
      },
    );
  }

  void onUserInteraction() {
    cancelPendingBettingListAutoScroll();
    // 取消之前的计时器
    _timer?.cancel();
    // 设置新的计时器，时间设置为你想要的锁屏延时时间
    _timer = Timer(Duration(seconds: 60 * state.LockScreenTime), () {
      lockScreen();
    });
  }

  void _initDayNightTheme() {
    final stored = StorageUtil.getBool(JiShuQiState.prefThemeFollowsTime);
    state.themeFollowsTime = stored ?? true;
    if (state.themeFollowsTime) {
      _applyThemeFromClock(silent: true);
    } else {
      BXLoading.syncTheme(state.isDarkMode);
    }
    _scheduleDayNightThemeTick();
    DayNightTheme.applySystemUiOverlayStyle(state.isDarkMode);
  }

  void _applyThemeFromClock({bool silent = false}) {
    final dark = DayNightTheme.isDarkPeriod(DateTime.now());
    if (state.isDarkMode == dark) return;
    state.isDarkMode = dark;
    BXLoading.syncTheme(dark);
    DayNightTheme.applySystemUiOverlayStyle(dark);
    update();
    if (!silent) {
      BXLoading.showToast(dark ? '已切换为夜间模式' : '已切换为白天模式');
    }
  }

  void _scheduleDayNightThemeTick() {
    _dayNightThemeTimer?.cancel();
    if (!state.themeFollowsTime) return;
    final now = DateTime.now();
    final next = DayNightTheme.nextBoundaryAfter(now);
    var wait = next.difference(now);
    if (wait.isNegative || wait.inMilliseconds < 500) {
      wait = const Duration(seconds: 1);
    } else {
      wait = wait + const Duration(seconds: 1);
    }
    _dayNightThemeTimer = Timer(wait, () {
      if (state.themeFollowsTime) {
        _applyThemeFromClock();
      }
      _scheduleDayNightThemeTick();
    });
  }

  /// 恢复按时间自动亮/暗
  void enableThemeFollowsTime() {
    dismissKeyboard();
    state.themeFollowsTime = true;
    unawaited(StorageUtil.saveBool(JiShuQiState.prefThemeFollowsTime, true));
    _applyThemeFromClock();
    _scheduleDayNightThemeTick();
    BXLoading.showToast('已开启按时间自动切换主题');
    update();
  }

  /// 更多功能：开/关按时间自动主题
  void toggleThemeFollowsTime() {
    dismissKeyboard();
    if (state.themeFollowsTime) {
      state.themeFollowsTime = false;
      unawaited(StorageUtil.saveBool(JiShuQiState.prefThemeFollowsTime, false));
      _dayNightThemeTimer?.cancel();
      BXLoading.showToast('已关闭自动主题');
      update();
      return;
    }
    enableThemeFollowsTime();
  }

  /// 临时切换亮/暗主题；是否按时间自动切换由更多功能里的自动主题开关决定。
  void toggleDarkMode() {
    dismissKeyboard();
    state.isDarkMode = !state.isDarkMode;
    BXLoading.syncTheme(state.isDarkMode);
    DayNightTheme.applySystemUiOverlayStyle(state.isDarkMode);
    update();
  }

  /// 切换图表显示/隐藏
  void toggleChartVisibility() {
    dismissKeyboard();
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
  juBuPingHeng(Object index, {v}) {
    guardAgainstKeyboardPop();
    final targetIndex = index != JiShuQiState.tempIndexCmdCancel &&
            state.currentTempIndex == index
        ? JiShuQiState.tempIndexCmdCancel
        : index;

    // 取消指令：取消局部平衡
    if (targetIndex == JiShuQiState.tempIndexCmdCancel) {
      if (state.currentTempIndex == 0) {
        return;
      }
      state.currentTempIndex = 0;
    } else if (_isEffectiveLocalTempIndex(targetIndex)) {
      state.currentTempIndex = targetIndex as int;
    }
    update();
    if (state.betRecordList.isNotEmpty) _getStatisticalAreasData(targetIndex);
  }

  //统计区的下拉刷新（网络错误 Toast 由 HttpService 统一处理）
  Future<void> refreshStatsArea() async {
    state.isRefreshing = true;
    update();
    var success = true;
    try {
      await _queryOperationRecords(isShowLoading: false);
      await _getStatisticalAreasData(JiShuQiState.tempIndexCmdKeep,
          isShowLoading: false);
      await _reloadBettingListTail(isShowLoading: false);
    } catch (_) {
      success = false;
    } finally {
      state.isRefreshing = false;
      update();
      statsRefreshController.finishRefresh(
        success ? IndicatorResult.success : IndicatorResult.fail,
        true,
      );
    }
  }

  //下拉刷新
  void onRefresh() {
    refreshStatsArea();
  }

  // 静默加载更多历史记录
  Future<int> onLoadMore({
    int count = 250,
    bool preserveViewport = true,
  }) {
    final completer = Completer<int>();
    // id 为 null 时 Dio 会发出 last_id= 无值，后端会走错分支；空列表用 -1。
    // 与后端 LoadMore 一致：数据为 created_at 升序，分页游标为当前已加载中最旧一条（first）的 id。
    final anchorId =
        state.betRecordList.isEmpty ? -1 : (state.betRecordList.first.id ?? -1);
    var networkLoadingVisible = true;
    void dismissNetworkLoading() {
      if (!networkLoadingVisible) return;
      networkLoadingVisible = false;
      BXLoading.dismiss();
    }

    // 保留列表顶部的小 Loading，同时显示项目统一的抖音双球网络 Loading。
    BXLoading.show(douyinStyle: true);
    BXGet<JsqBetRecordModel>(Api.loadMore,
        params: {
          "last_id": anchorId,
          "uid": GetStore.getInstance().userModel.userId,
          "c": count
        },
        //"c"每页多少个数据
        isShowLoading: false,
        showError: false,
        success: (isSuccess, code, message, results) {
          dismissNetworkLoading();
          if (!isSuccess) {
            if (!completer.isCompleted) completer.complete(0);
            return;
          }

          if (results.isEmpty) {
            _hasMoreBettingHistory = false;
            if (state.betRecordList.isEmpty) {
              update();
            }
            if (!completer.isCompleted) completer.complete(0);
            return;
          }

          if (results.isNotEmpty) {
            double? keptPixels;
            if (scrollController.hasClients) {
              keptPixels = scrollController.position.pixels;
            }
            state.betRecordList.insertAll(0, results);
            update();
            if (preserveViewport && keptPixels != null) {
              _schedulePreserveScrollAfterPrepend(keptPixels, results.length);
            }
          }
          if (!completer.isCompleted) completer.complete(results.length);
        },
        failed: (_, __) {
          dismissNetworkLoading();
          if (!completer.isCompleted) completer.complete(0);
        },
        onModel: (m) => JsqBetRecordModel.fromJson(m));
    return completer.future;
  }

  changeChart() {
    dismissKeyboard();
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
    var list = state.betRecordList
        .map((e) => (e.shuyingzhi ?? 0) < 0 ? "闲家" : "庄家")
        .toList();
    state.initializeBigRoad();
    for (var value in list) {
      updateBigRoad(value);
    }
    _scheduleRoadMapScrollAfterRebuild();
  }
}
