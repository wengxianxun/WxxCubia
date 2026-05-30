import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wxx_cubia/pages/game_service/game_service_controller.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

/// PopStar 游戏数据管理器
///
/// 这是一个单例模式的类，用于管理：
/// - 当前关卡、分数
/// - 历史最高分、历史关卡分数记录
/// - 连消分数表（消除多少个方块对应多少分）
/// - 剩余方块奖励表（结算剩余方块奖励分数）
/// - 游戏状态保存与加载
///
/// 完全移植自经典 Cocos2d-x PopStar 游戏的核心逻辑。
///
const int CONST_dailyAdWatchedCount = 10; //每天看激励广告的次数

class GameDataManager {
  /// 单例对象
  static final GameDataManager _instance = GameDataManager._internal();
  final gameService = Get.find<GameServiceController>();

  /// 工厂构造函数，确保只返回同一个实例
  factory GameDataManager() {
    return _instance;
  }

  /// 私有构造函数（只在内部调用一次）
  // 修改私有构造函数以支持异步初始化
  GameDataManager._internal() {
    _init();
  }

  // 添加一个标志，用于检查初始化是否完成
  bool _isInitialized = false;

  // 添加getter方法，用于检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化分数表
  // 修改初始化方法，添加加载刷新次数的逻辑
  // 在GameDataManager类中添加以下字段（大约在第100行左右）

  // 广告相关字段
  // 每天看广告的次数
  int _dailyAdWatchedCount = 0;
  // 上次看广告的时间戳
  int _lastAdWatchedTime = 0;
  // 上次重置广告计数的日期（用于每天重置）
  int _lastAdCountResetDate = 0;

  // 在_getInit方法中添加初始化广告相关数据（大约在第140行左右）
  Future<void> _init() async {
    // 连消得分表
    const REDUCENUM_SCORE_MAP = [
      [2, 20],
      [3, 45],
      [4, 80],
      [5, 125],
      [6, 180],
      [7, 245],
      [8, 320],
      [9, 405],
      [10, 500],
      [11, 605],
      [12, 720],
      [13, 845],
      [14, 980],
      [15, 1125],
      [16, 1280],
      [17, 1445],
      [18, 1620],
      [19, 1805],
      [20, 2000],
      [21, 2205],
      [22, 2420],
      [23, 2645],
      [24, 2880],
      [25, 3125],
      [26, 3380],
      [27, 3645],
      [28, 3920],
      [29, 4205],
      [30, 4500],
      [31, 4805],
      [32, 5105],
      [33, 5405],
      [34, 5805],
      [35, 6105],
    ];

    // 剩余方块奖励表
    const LEFTNUM_SCORE_MAP = [
      [0, 2000],
      [1, 1980],
      [2, 1920],
      [3, 1820],
      [4, 1680],
      [5, 1500],
      [6, 1280],
      [7, 1020],
      [8, 720],
      [9, 380],
      [10, 260],
    ];

    // 初始化到 Map
    for (var pair in REDUCENUM_SCORE_MAP) {
      reduceNumScoreMap[pair[0]] = pair[1];
    }
    for (var pair in LEFTNUM_SCORE_MAP) {
      leftNumScoreMap[pair[0]] = pair[1];
    }

    // 加载历史最高分
    await loadHistoryScore();

    // 加载刷新次数
    await loadRefreshCount();

    //加载锤子数量
    await loadHammerCount();

    // 加载改色笔数量
    await loadPenCount();

    // 加载生命数量
    await loadLifeCount();

    // 加载上次免费领取时间
    await loadLastFreeRefreshTime();

    // 新增：加载广告观看记录
    await loadAdWatchedData();

    // 加载消除方式
    await load_doubleTap();

    // 标记初始化完成
    _isInitialized = true;
  }

  // 在类的其他部分添加以下方法

  /// 检查是否可以观看激励广告
  bool canWatchRewardedAd() {
    // 如果未初始化，返回false
    if (!_isInitialized) {
      return false;
    }

    final now = DateTime.now();
    final nowMillis = now.millisecondsSinceEpoch;
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    // 检查是否需要重置每日计数
    if (_lastAdCountResetDate != todayDate) {
      _dailyAdWatchedCount = 0;
      _lastAdCountResetDate = todayDate;
      _saveAdWatchedData();
    }

    // 检查每天观看次数是否超过5次
    if (_dailyAdWatchedCount >= CONST_dailyAdWatchedCount) {
      return false;
    }

    // 检查两次广告之间的间隔是否超过5分钟（300000毫秒）
    if (_lastAdWatchedTime > 0 &&
        nowMillis - _lastAdWatchedTime < 5 * 60 * 1000) {
      return false;
    }

    return true;
  }

  /// 记录观看广告
  void recordAdWatched() {
    final now = DateTime.now();
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    // 如果是新的一天，重置计数
    if (_lastAdCountResetDate != todayDate) {
      _dailyAdWatchedCount = 0;
      _lastAdCountResetDate = todayDate;
    }

    // 增加观看次数
    _dailyAdWatchedCount++;
    // 更新上次观看时间
    _lastAdWatchedTime = now.millisecondsSinceEpoch;

    // 保存数据
    _saveAdWatchedData();
  }

  /// 获取距离下次可以观看广告的剩余时间（毫秒）
  int getTimeUntilNextAdAvailable() {
    if (!_isInitialized) {
      return 0;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final requiredInterval = 5 * 60 * 1000; // 5分钟

    if (_lastAdWatchedTime > 0 && now - _lastAdWatchedTime < requiredInterval) {
      return requiredInterval - (now - _lastAdWatchedTime);
    }

    return 0;
  }

  /// 获取今天剩余可观看广告的次数
  int getRemainingAdsToday() {
    if (!_isInitialized) {
      return 0;
    }

    final now = DateTime.now();
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;

    // 如果是新的一天，重置计数
    if (_lastAdCountResetDate != todayDate) {
      return CONST_dailyAdWatchedCount; // 新的一天有5次机会
    }

    return CONST_dailyAdWatchedCount - _dailyAdWatchedCount;
  }

  // 保存广告观看数据
  Future<void> _saveAdWatchedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyAdWatchedCount', _dailyAdWatchedCount);
    await prefs.setInt('lastAdWatchedTime', _lastAdWatchedTime);
    await prefs.setInt('lastAdCountResetDate', _lastAdCountResetDate);
  }

  // 加载广告观看数据
  Future<void> loadAdWatchedData() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyAdWatchedCount = prefs.getInt('dailyAdWatchedCount') ?? 0;
    _lastAdWatchedTime = prefs.getInt('lastAdWatchedTime') ?? 0;
    _lastAdCountResetDate = prefs.getInt('lastAdCountResetDate') ?? 0;

    // 检查是否需要重置（如果日期不匹配）
    final now = DateTime.now();
    final todayDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    if (_lastAdCountResetDate != todayDate) {
      _dailyAdWatchedCount = 0;
      _lastAdCountResetDate = todayDate;
      _saveAdWatchedData();
    }
  }

  /// 清理游戏数据，重置当前状态
  void dispose() {
    gameLevel = 1;
    curScore = 0;
  }

  /// 当前关卡
  int gameLevel = 1;

  /// 当前累计分数
  int curScore = 0;

  /// 当前关卡开始时的分数（用于重新开始关卡时恢复分数）
  int _levelStartScore = 0;

  /// 获取当前关卡开始时的分数
  int get levelStartScore => _levelStartScore;

  /// 设置当前关卡开始时的分数
  void setLevelStartScore(int score) => _levelStartScore = score;

  /// 历史最高总分（所有关卡累计）
  int historyScore = 0;

  /// 当前刷新次数
  int _refreshCount = 0;

  /// 消除方式（单机/双击）
  bool _doubleTap = true; //默认双击

  /// 上次免费领取刷新次数的时间戳
  int _lastFreeRefreshTime = 0;

  /// 获取当前刷新次数
  int get refreshCount => _refreshCount;

  /// 消除方式（单机/双击）
  bool get doubleTap => _doubleTap;

  /// 当前锤子数量
  int _hammerCount = 0;

  /// 获取当前锤子数量
  get hammerCount => _hammerCount;

  /// 当前改色笔数量
  int _penCount = 0;

  /// 获取当前改色笔数量
  get penCount => _penCount;

  /// 当前生命数量
  int _lifeCount = 0;

  /// 获取当前改色笔数量
  get lifeCount => _lifeCount;

  /// 上次上报分数的时间戳
  int _lastReportTime = 0;

  /// 分数上报节流定时器
  Timer? _reportScoreDebounce;

  /// 消除多少个同色方块对应的分数表
  /// 例如：reduceNumScoreMap[3] = 45 表示消除 3 个同色方块得 45 分
  final Map<int, int> reduceNumScoreMap = {};

  /// 游戏结束时剩余多少个方块对应的额外奖励表
  /// 例如：leftNumScoreMap[0] = 2000 表示清空所有剩余，奖励 2000 分
  final Map<int, int> leftNumScoreMap = {};

  /// 获取当前总分
  int getScore() => curScore;

  /// 设置当前总分
  void setScore(int score) {
    curScore = score;
    setHistoryScore(curScore);
  }

  /// 获取当前关卡
  int getLevel() => gameLevel;

  /// 设置当前关卡
  void setLevel(int level) => gameLevel = level;

  /// 获取历史最高总分
  int getHistoryScore() => historyScore;

  /// 更新历史最高总分
  void setHistoryScore(int score) {
    // 分数没有变化，则不处理
    if (score > historyScore) {
      historyScore = score;
      // 这里可以加上 SharedPreferences 永久保存
      _saveHistoryScore();

      // 使用防抖机制控制上报频率
      _reportScoreDebounce?.cancel();
      _reportScoreDebounce = Timer(const Duration(seconds: 5), () {
        // 延迟2秒上报
        // _tryUploadScore();
      });
    }
  }

  /// 尝试上报分数
  Future<void> _tryUploadScore() async {
    print("当前最高分$historyScore");
    // 如果需要，可以在这里增加更复杂的逻辑，比如检查网络状态等
    // // ✅ 强制确保登录
    // await GamesServices.signIn();
    // final isSignedIn = await GamesServices.isSignedIn;
    // if (isSignedIn) {
    //   try {
    //     await GamesServices.submitScore(
    //       score: Score(
    //         iOSLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
    //         androidLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
    //         value: historyScore,
    //       ),
    //     );
    //   } catch (e) {
    //     print("提交分数失败: $e");
    //   }
    // }
    // gameService.tryUploadScore(historyScore);

    _lastReportTime = DateTime.now().millisecondsSinceEpoch;
  }

  /// 根据关卡号获取该关的目标分数
  ///
  /// 经典规则：
  /// - level=1 → 1000
  /// - level=2 → 3000
  /// - 3~10 每关+3000
  /// - 10+ 每关+4000
  int getTargetScoreByLevel(int level) {
    if (level == 1) {
      return 1000;
    } else if (level == 2) {
      return 3000;
    } else if (level >= 3 && level <= 10) {
      return 3000 + 3000 * (level - 2);
    } else {
      return 27000 + 4000 * (level - 10);
    }
  }

  /// 根据一次连消的数量，返回总得分（阶梯式加分）
  ///
  /// 例如：
  /// 连消2个：5 + 15 = 20
  /// 连消3个：5 + 15 + 25 = 45
  /// 连消4个：5 + 15 + 25 + 35 = 80
  int getScoreByReduceNum(int num) {
    if (num < 2) return 0;

    int total = 0;
    for (int i = 1; i <= num; i++) {
      total += 5 + (i - 1) * 10;
    }
    return total;
  }

  /// 返回每颗星星的分数列表
  ///
  /// 例如：
  /// getScoreListByReduceNum(3) -> [5, 15, 25]
  List<int> getScoreListByReduceNum(int num) {
    if (num < 2) return [];

    List<int> scores = [];
    for (int i = 1; i <= num; i++) {
      scores.add(5 + (i - 1) * 10);
    }
    return scores;
  }

  /// 根据游戏结束时剩余的星星数量，返回额外奖励
  int getScoreByLeftNum(int num) {
    return leftNumScoreMap[num] ?? 0;
  }

  // 保存历史最高分
  Future<void> _saveHistoryScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('historyScore', historyScore);
  }

  // 加载历史最高分
  Future<void> loadHistoryScore() async {
    final prefs = await SharedPreferences.getInstance();
    historyScore = prefs.getInt('historyScore') ?? 0;
  }

  /// 设置刷新次数
  void set refreshCount(int count) {
    _refreshCount = count;
    // 保存刷新次数到本地存储
    _saveRefreshCount();
  }

  /// 增加刷新次数
  void addRefreshCount(int count) {
    _refreshCount += count;
    _saveRefreshCount();
  }

  /// 判断是否可以免费领取刷新次数（每日限制）
  bool canGetFreeRefresh() {
    // 如果未初始化，返回false防止频繁领取
    if (!_isInitialized) {
      return false;
    }

    final now = DateTime.now();
    final lastTime = DateTime.fromMillisecondsSinceEpoch(_lastFreeRefreshTime);

    // 如果是同一天（年月日相同），则不能再次领取
    if (lastTime.year == now.year &&
        lastTime.month == now.month &&
        lastTime.day == now.day) {
      return false;
    }
    return true;
  }

  /// 领取每日免费次数
  void claimTodayFree() {
    if (HuuuaConfig.isDebug) {
      addRefreshCount(100);
      addHammerCount(100);
      addPenCount(100);
    } else {
      addRefreshCount(1);
      addHammerCount(1);
      addPenCount(1);
      addLifeCount(1);
    }

    _lastFreeRefreshTime = DateTime.now().millisecondsSinceEpoch;
    _saveLastFreeRefreshTime();
    SmartDialog.showToast(
      "claim_refresh_success".tr,
      alignment: Alignment.center,
    );
  }

  // 保存上次免费领取时间
  Future<void> _saveLastFreeRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastFreeRefreshTime', _lastFreeRefreshTime);
  }

  // 加载上次免费领取时间
  Future<void> loadLastFreeRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastFreeRefreshTime = prefs.getInt('lastFreeRefreshTime') ?? 0;
  }

  /// 减少刷新次数
  bool reduceRefreshCount() {
    if (_refreshCount > 0) {
      _refreshCount--;
      _saveRefreshCount();
      return true;
    }
    return false;
  }

  /// 重置刷新次数为默认值
  void resetRefreshCount() {
    _saveRefreshCount();
  }

  /// 保存刷新次数到本地
  Future<void> _saveRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refreshCount', _refreshCount);
    print('刷新次数已保存: $_refreshCount');
  }

  /// 从本地加载刷新次数
  Future<void> loadRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    _refreshCount = prefs.getInt('refreshCount') ?? 0;
    print('刷新次数已加载: $_refreshCount');
  }

  /// 加载消除方式
  Future<void> load_doubleTap() async {
    final prefs = await SharedPreferences.getInstance();
    _doubleTap = prefs.getBool('_doubleTap') ?? true;
  }

  /// 保存消除方式
  Future<void> save_doubleTap(bool isDouble) async {
    final prefs = await SharedPreferences.getInstance();
    _doubleTap = isDouble;
    await prefs.setBool('_doubleTap', isDouble);
  }

  // 保存游戏状态
  // 修改saveGameState方法，添加刷新次数参数
  Future<void> saveGameState(
    List<List<int?>> gridData, {
    int refreshCount = 3,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 保存基础游戏数据
    await prefs.setInt('savedGameLevel', gameLevel);
    await prefs.setInt('savedGameScore', curScore);
    await prefs.setInt('savedGameRefreshCount', refreshCount); // 保存刷新次数
    await prefs.setBool('hasSavedGame', true);

    // 保存网格状态
    final gridJson = json.encode(gridData);
    await prefs.setString('savedGameGrid', gridJson);

    print('游戏状态已保存: 关卡 $gameLevel, 分数 $curScore, 刷新次数 $refreshCount');
  }

  // 修改loadGameState方法，添加加载刷新次数
  Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查是否有保存的游戏
    if (prefs.getBool('hasSavedGame') != true) {
      return null;
    }

    // 加载基础游戏数据
    final level = prefs.getInt('savedGameLevel') ?? 1;
    final score = prefs.getInt('savedGameScore') ?? 0;
    final refreshCount = prefs.getInt('savedGameRefreshCount') ?? 3; // 加载刷新次数
    final hammerCount = prefs.getInt('savedGameHammerCount') ?? 0; // 加载锤子数量
    final penCount = prefs.getInt('savedGamePenCount') ?? 0; // 加载改色笔数量
    // 加载网格状态
    final gridJson = prefs.getString('savedGameGrid');
    if (gridJson == null) {
      return null;
    }

    final List<dynamic> gridList = json.decode(gridJson);
    final List<List<int?>> gridData = gridList.map((row) {
      return (row as List<dynamic>).map((value) {
        return value == null ? null : value as int;
      }).toList();
    }).toList();

    return {
      'level': level,
      'score': score,
      'grid': gridData,
      'refreshCount': refreshCount, // 返回刷新次数
      'hammerCount': hammerCount, // 返回锤子数量
      'penCount': penCount,
    };
  }

  // 修改clearGameState方法，清除刷新次数相关数据
  Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedGameLevel');
    await prefs.remove('savedGameScore');
    await prefs.remove('savedGameGrid');
    await prefs.remove('savedGameRefreshCount'); // 清除保存的刷新次数
    await prefs.setBool('hasSavedGame', false);
    dispose();
    print('游戏状态已清除');
  }

  // 检查是否有保存的游戏
  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSavedGame') ?? false;
  }

  // /// 设置锤子数量
  // void set hammerCount(int count) {
  //   _hammerCount = count;
  //   // 保存锤子数量到本地存储
  //   _saveHammerCount();
  // }

  /// 增加锤子数量
  void addHammerCount(int count) {
    _hammerCount += count;
    _saveHammerCount();
  }

  /// 减少锤子数量
  bool reduceHammerCount() {
    if (_hammerCount > 0) {
      _hammerCount--;
      _saveHammerCount();
      return true;
    }
    return false;
  }

  /// 保存锤子数量到本地
  Future<void> _saveHammerCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hammerCount', _hammerCount);
    print('锤子数量已保存: $_hammerCount');
  }

  /// 从本地加载锤子数量
  Future<void> loadHammerCount() async {
    final prefs = await SharedPreferences.getInstance();
    _hammerCount = prefs.getInt('hammerCount') ?? 0;
    print('锤子数量已加载: $_hammerCount');
  }

  /// 增加改色笔数量
  void addPenCount(int count) {
    _penCount += count;
    _savePenCount();
  }

  /// 减少改色笔数量
  bool reducePenCount() {
    if (_penCount > 0) {
      _penCount--;
      _savePenCount();
      return true;
    }
    return false;
  }

  /// 保存改色笔数量到本地
  Future<void> _savePenCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('penCount', _penCount);
    print('改色笔数量已保存: $_penCount');
  }

  /// 从本地加载改色笔数量
  Future<void> loadPenCount() async {
    final prefs = await SharedPreferences.getInstance();
    _penCount = prefs.getInt('penCount') ?? 0;
    print('改色笔数量已加载: $_penCount');
  }

  /// 增加生命数量
  void addLifeCount(int count) {
    _lifeCount += count;
    _saveLifeCount();
  }

  /// 减少生命
  bool reduceLifeCount() {
    if (_lifeCount > 0) {
      _lifeCount--;
      _saveLifeCount();
      return true;
    }
    return false;
  }

  /// 保存改色笔数量到本地
  Future<void> _saveLifeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lifeCount', _lifeCount);
    print('生命数量已保存: $_lifeCount');
  }

  /// 从本地加载改色笔数量
  Future<void> loadLifeCount() async {
    final prefs = await SharedPreferences.getInstance();
    _lifeCount = prefs.getInt('lifeCount') ?? 0;
    print('生命数量已加载: $_lifeCount');
  }

  bool canLifeRevive() {
    if (_lifeCount > 0) {
      return true;
    }
    return false;
  }
}

/// 单例全局访问
final gameDataManager = GameDataManager();
