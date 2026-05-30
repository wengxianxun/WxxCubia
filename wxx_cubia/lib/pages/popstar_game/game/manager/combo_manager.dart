import 'dart:async';

// combo_manager.dart

typedef ComboCallback = void Function(int combo);
typedef ComboBreakCallback = void Function(int combo);

class ComboManager {
  ComboManager({
    this.comboBreakTime = 10.0,
    this.minClearForCombo = 2,
    this.onCombo,
    this.onComboBreak,
  });

  /// 连击时间窗口（秒）
  final double comboBreakTime;

  /// 最少消除几个才算一次 combo
  final int minClearForCombo;

  /// combo 触发回调
  final ComboCallback? onCombo;

  /// combo 中断回调
  final ComboBreakCallback? onComboBreak;

  int _combo = -1;
  double _lastClearTime = 0;
  Timer? _comboTimer;

  int get combo => _combo;
  bool get isCombining => _combo > 1;

  /// 每次消除后调用
  void onClear({required int clearCount, required double currentTime}) {
    // 消除数量不够，不算 combo
    if (clearCount < minClearForCombo) {
      _breakCombo();
      return;
    }

    _lastClearTime = currentTime;
    _combo++;

    if (_combo >= 1) {
      // 取消之前的计时器
      _comboTimer?.cancel();

      // 设置新的计时器，在 comboWindow 秒后中断 combo
      _comboTimer = Timer(
        Duration(seconds: comboBreakTime.toInt()),
        _breakCombo,
      );

      onCombo?.call(_combo);
    }
  }

  /// 外部强制打断（比如无可消除、回合结束）
  void breakCombo() {
    _breakCombo();
  }

  void _breakCombo() {
    // 取消计时器
    _comboTimer?.cancel();
    _comboTimer = null;

    if (_combo >= 1) {
      onComboBreak?.call(combo);
    }
    _combo = -1;
    _lastClearTime = 0;
  }
}
