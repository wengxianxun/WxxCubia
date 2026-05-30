import 'dart:async';

import 'package:flutter_tencentad/flutter_tencentad.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wxx_cubia/util/consent_manager.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

/// 广告加载结果
enum AdLoadResult {
  none, // 未知
  admob, // Admob加载成功
  tencent, // 腾讯加载成功
  failed, // 全部失败
}

/// 激励广告管理器
///
/// 实现腾讯和Admob激励广告的预加载和交替展示逻辑
///
/// 该类是单例模式，确保全局只有一个实例。
/// 它负责初始化广告SDK，预加载广告，以及根据配置交替展示广告。
///
/// 它还提供了检查广告加载状态的方法，以及展示广告的方法。
///
/// 它还提供了检查广告是否加载成功的方法，以及检查是否有任何广告已加载的方法。
///
/// 它还提供了检查广告是否准备就绪的方法，以及检查是否有任何广告已准备就绪的方法。
class AdManagerRewarded {
  static final AdManagerRewarded _instance = AdManagerRewarded._internal();
  factory AdManagerRewarded() => _instance;

  AdManagerRewarded._internal();

  /// 统一初始化所有广告SDK
  Future<void> initialize() async {
    await Future.wait([initializeAdmobAds(), initTencentAd()]);
  }

  // -------------- tencent --------------------------------//
  bool _isTencentRewardedLoaded = false;
  bool _isTencentRewardedReady = false;
  void Function(bool success)? _tencentAdLoadCallback;
  void Function(RewardItem)? _tencentRewardCallback;
  void Function()? _externalOnAdClosed; // 添加成员变量
  // -------------- admob --------------------------------//
  final ConsentManager _consentManager = ConsentManager();
  RewardedAd? _rewardedAd;
  bool _isMobileAdsInitialized = false;
  bool _isPreloading = false;
  bool _isAdmobAdPreloaded = false;
  int _admobRetryCount = 0;

  // 交替展示标志：true = 下一个展示腾讯，false = 下一个展示Admob
  bool _nextAdIsTencent = true;

  // 两个平台的加载状态
  bool get isTencentRewardedLoaded => _isTencentRewardedLoaded;
  bool get isAdmobRewardedLoaded => _rewardedAd != null;

  // 检查是否有任何广告已加载
  bool get hasAnyAdLoaded => _isTencentRewardedLoaded || _rewardedAd != null;

  /// 初始化广告SDK
  Future<void> initializeAdmobAds() async {
    if (_isMobileAdsInitialized) {
      return;
    }

    await _gatherConsent();

    if (await _consentManager.canRequestAds()) {
      _isMobileAdsInitialized = true;
    }
  }

  /// 初始化腾讯广告
  Future<void> initTencentAd() async {
    FlutterTencentAdStream.initAdStream(
      flutterTencentadRewardCallBack: FlutterTencentadRewardCallBack(
        onShow: () {
          print("腾讯激励广告显示");
        },
        onClick: () {
          print("腾讯激励广告点击");
        },
        onFail: (code, message) {
          print("腾讯激励广告失败 $code $message");
          _isTencentRewardedReady = false;
          _isTencentRewardedLoaded = false;
          _tencentAdLoadCallback?.call(false);
          _tencentAdLoadCallback = null;
        },
        onClose: () {
          print("腾讯激励广告关闭");
          _isTencentRewardedReady = false;
          _isTencentRewardedLoaded = false;
          _externalOnAdClosed?.call(); // 调用外部回调
          // 广告关闭后重新预加载
          _preloadTencentRewardedAd();
        },
        onReady: () async {
          print("腾讯激励广告预加载准备就绪");
          _isTencentRewardedReady = true;
          _isTencentRewardedLoaded = true;
          _tencentAdLoadCallback?.call(true);
          _tencentAdLoadCallback = null;
        },
        onUnReady: () {
          print("腾讯激励广告预加载未准备就绪");
          _isTencentRewardedReady = false;
          _isTencentRewardedLoaded = false;
        },
        onVerify: (transId, rewardName, rewardAmount) {
          print("腾讯激励广告奖励  $transId   $rewardName   $rewardAmount");
          _tencentRewardCallback?.call(RewardItem(1, "tencent"));
          _tencentRewardCallback = null;
        },
        onFinish: () {
          print("腾讯激励广告完成");
        },
        // onECPM: (ecpmLevel, ecpm) async {
        //   print("腾讯激励广告竞价  ecpmLevel=$ecpmLevel  ecpm=$ecpm");
        //   if (ecpm > 0) {
        //     await FlutterTencentad.showRewardVideoAd(
        //       result: FlutterTencentBiddingResult().success(ecpm, 0),
        //     );
        //   } else {
        //     await FlutterTencentad.showRewardVideoAd(
        //       result: FlutterTencentBiddingResult().fail(
        //         1000,
        //         FlutterTencentAdBiddingLossReason.LOW_PRICE,
        //         FlutterTencentAdADNID.othoerADN,
        //       ),
        //     );
        //   }
        // },
      ),
    );
  }

  /// 获取用户同意
  Future<void> _gatherConsent() async {
    Completer<void> consentCompleter = Completer<void>();

    _consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        print(
          "Consent not obtained: ${consentGatheringError.errorCode}: ${consentGatheringError.message}",
        );
      }
      consentCompleter.complete();
    });

    return consentCompleter.future;
  }

  /// 预加载腾讯激励广告
  Future<void> _preloadTencentRewardedAd() async {
    if (_isTencentRewardedReady) {
      return;
    }

    print("开始预加载腾讯激励广告...");
    loadTencentRewardVideoAd();
  }

  Future<void> loadTencentRewardVideoAd() async {
    await FlutterTencentad.loadRewardVideoAd(
      androidId: "9300749654944959",
      iosId: "7330286103243870",
      userID: "",
      rewardName: "激励",
      rewardAmount: 1,
      customData: "",
      downloadConfirm: true,
      isBidding: false,
    );
  }

  /// 显示腾讯激励广告
  Future<void> showTencentAd() async {
    if (_isTencentRewardedReady) {
      await FlutterTencentad.showRewardVideoAd();
      _isTencentRewardedReady = false;
      _isTencentRewardedLoaded = false;
    } else {
      print("腾讯激励广告未准备好，正在重新加载...");
      _preloadTencentRewardedAd();
    }
  }

  /// 预加载Admob激励广告
  Future<void> _preloadAdmobRewardedAd() async {
    if (_rewardedAd != null || _isPreloading) {
      return;
    }

    _isPreloading = true;
    try {
      await initializeAdmobAds();
      if (await _consentManager.canRequestAds()) {
        await _loadAdmobRewardedAdWithCallback((success) {});
      }
    } catch (e) {
      print('Admob广告预加载异常: $e');
      _scheduleAdmobRetry();
    } finally {
      _isPreloading = false;
    }
  }

  /// 安排Admob广告重试
  void _scheduleAdmobRetry() {
    _admobRetryCount++;

    if (_admobRetryCount <= 5) {
      print('Admob广告重试中 (尝试 $_admobRetryCount/5)...');
      Future.delayed(const Duration(seconds: 30), () {
        if (_rewardedAd == null) {
          _preloadAdmobRewardedAd();
        }
      });
    } else {
      print('Admob广告重试次数已达上限，停止重试');
      _admobRetryCount = 0;
    }
  }

  // ---------------------- 对外接口 ----------------------//

  // 广告加载状态
  AdLoadResult _loadResult = AdLoadResult.none;
  bool _admobLoaded = false;
  bool _tencentLoaded = false;

  /// 加载刷新次数的激励广告（外部调用接口）
  ///
  /// 如果已有广告可用，直接回调成功，不重新加载
  /// 否则同时加载腾讯和Admob激励广告，哪个先加载完成就回调哪个
  /// 只有两个平台都加载失败才回调失败
  Future<void> loadRefreshTimesRewardedAd({
    void Function(AdLoadResult result)? onAdLoaded,
    void Function()? onAdFailedToLoad,
  }) async {
    // 先检查是否已有广告可用，避免重复加载
    if (_rewardedAd != null) {
      // Admob已有广告
      onAdLoaded?.call(AdLoadResult.admob);
      return;
    }
    if (_isTencentRewardedReady) {
      // 腾讯已有广告
      onAdLoaded?.call(AdLoadResult.tencent);
      return;
    }

    // 重置加载状态
    _loadResult = AdLoadResult.none;
    _admobLoaded = false;
    _tencentLoaded = false;

    // 同时启动两个平台的广告加载
    await Future.wait([
      _loadAdmobRewardedAdWithCallback((success) {
        if (success) {
          _admobLoaded = true;
          _notifyAdLoaded(onAdLoaded);
        } else {
          _checkAllFailed(onAdFailedToLoad);
        }
      }),
      _preloadTencentRewardedAdWithCallback((success) {
        if (success) {
          _tencentLoaded = true;
          _notifyAdLoaded(onAdLoaded);
        } else {
          _checkAllFailed(onAdFailedToLoad);
        }
      }),
    ]);
  }

  /// 检查是否所有平台都加载失败
  void _checkAllFailed(void Function()? onAdFailedToLoad) {
    // 如果已有广告可用，不需要回调失败
    if (_rewardedAd != null || _isTencentRewardedReady) {
      return;
    }
    if (_admobLoaded == false && _tencentLoaded == false) {
      _loadResult = AdLoadResult.failed;
      onAdFailedToLoad?.call();
    }
  }

  /// 通知广告加载成功
  void _notifyAdLoaded(void Function(AdLoadResult result)? onAdLoaded) {
    if (_admobLoaded && !_tencentLoaded) {
      if (_loadResult != AdLoadResult.admob) {
        _loadResult = AdLoadResult.admob;
        onAdLoaded?.call(AdLoadResult.admob);
      }
    } else if (_tencentLoaded && !_admobLoaded) {
      if (_loadResult != AdLoadResult.tencent) {
        _loadResult = AdLoadResult.tencent;
        onAdLoaded?.call(AdLoadResult.tencent);
      }
    } else if (_admobLoaded && _tencentLoaded) {
      // 两者都加载成功，优先使用腾讯
      if (_loadResult != AdLoadResult.tencent) {
        _loadResult = AdLoadResult.tencent;
        onAdLoaded?.call(AdLoadResult.tencent);
      }
    }
  }

  /// 带回调的Admob广告加载
  Future<void> _loadAdmobRewardedAdWithCallback(
    void Function(bool success) callback,
  ) async {
    await initializeAdmobAds();

    if (!await _consentManager.canRequestAds()) {
      callback(false);
      return;
    }

    _rewardedAd?.dispose();
    _rewardedAd = null;

    String adUnitId = HuuuaConfig.instance.getAdmobBannerId(
      admob_type.admob_refresh_times_rewarded,
    );

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _admobRetryCount = 0;
            },
          );

          _rewardedAd = ad;
          _isAdmobAdPreloaded = true;
          _admobRetryCount = 0;
          print("Admob激励广告加载成功");
          callback(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Admob激励广告加载失败: $error');
          _isAdmobAdPreloaded = false;
          callback(false);
          _scheduleAdmobRetry();
        },
      ),
    );
  }

  /// 带回调的腾讯广告加载
  Future<void> _preloadTencentRewardedAdWithCallback(
    void Function(bool success) callback,
  ) async {
    if (_isTencentRewardedReady) {
      callback(true);
      return;
    }

    // 设置回调函数，广告加载完成时会调用
    _tencentAdLoadCallback = callback;

    print("开始预加载腾讯激励广告...");
    loadTencentRewardVideoAd();
  }

  /// 显示激励广告（交替展示）
  ///
  /// 如果两者都加载成功，根据交替标志决定展示哪个
  /// 如果只有一个加载成功，展示加载成功的那个
  /// 如果都没加载成功，返回false
  Future<bool> showRewardedAd({
    required void Function(RewardItem) onUserEarnedReward,
    void Function()? onAdFailedToShow,
    void Function()? onAdClosed,
  }) async {
    // 优先展示交替标志指定的广告
    if (_nextAdIsTencent && _isTencentRewardedReady) {
      await _showTencentAndSwitch(onUserEarnedReward, onAdClosed);
      return true;
    } else if (!_nextAdIsTencent && _rewardedAd != null) {
      await _showAdmobAndSwitch(onUserEarnedReward, onAdClosed);
      return true;
    }

    // 交替指定的广告没准备好，尝试另一个平台
    if (_nextAdIsTencent && _rewardedAd != null) {
      await _showAdmobAndSwitch(onUserEarnedReward, onAdClosed);
      return true;
    } else if (!_nextAdIsTencent && _isTencentRewardedReady) {
      await _showTencentAndSwitch(onUserEarnedReward, onAdClosed);
      return true;
    }

    // 两者都没准备好
    print("两个平台的激励广告都没准备好");
    onAdFailedToShow?.call();

    // 尝试加载两个平台的广告
    _preloadTencentRewardedAd();
    _preloadAdmobRewardedAd();

    return false;
  }

  /// 展示腾讯广告并切换交替标志
  Future<void> _showTencentAndSwitch(
    void Function(RewardItem) onUserEarnedReward,
    void Function()? onAdClosed,
  ) async {
    // 设置奖励回调
    _tencentRewardCallback = onUserEarnedReward;
    _externalOnAdClosed = onAdClosed;
    await showTencentAd();
    _nextAdIsTencent = false; // 切换到Admob
    // onAdClosed?.call();
  }

  /// 展示Admob广告并切换交替标志
  Future<void> _showAdmobAndSwitch(
    void Function(RewardItem) onUserEarnedReward,
    void Function()? onAdClosed,
  ) async {
    if (_rewardedAd == null) {
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdImpression: (ad) {},
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        _nextAdIsTencent = true;
        _preloadAdmobRewardedAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _nextAdIsTencent = true; // 切换到腾讯
        _preloadAdmobRewardedAd();
        onAdClosed?.call();
      },
      onAdClicked: (ad) {},
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        onUserEarnedReward(rewardItem);
      },
    );

    _nextAdIsTencent = true; // 切换到腾讯
  }

  /// 批量预加载两个平台的广告
  Future<void> preloadAllAds({
    void Function(AdLoadResult result)? onAdLoaded,
    void Function()? onAdFailedToLoad,
  }) async {
    // 同时启动两个平台的广告预加载
    await Future.wait([_preloadTencentRewardedAd(), _preloadAdmobRewardedAd()]);
  }

  /// 清理资源
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isTencentRewardedReady = false;
    _isTencentRewardedLoaded = false;
    _isAdmobAdPreloaded = false;
  }
}
