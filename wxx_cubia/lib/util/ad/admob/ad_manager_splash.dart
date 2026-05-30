import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

class AdManagerSplash {
  // 工厂模式
  factory AdManagerSplash() => _getInstance();
  static AdManagerSplash get instance => _getInstance();
  static AdManagerSplash? _instance;
  static AdManagerSplash _getInstance() {
    _instance ??= AdManagerSplash._internal();
    return _instance!;
  }

  // 上次调用时间
  late DateTime lastShowTime;
  AdManagerSplash._internal() {
    this.lastShowTime = DateTime.now().subtract(Duration(seconds: 600));
  }

  void defaultInit() {
    _isShowingAd = false;

    Future.delayed(Duration(seconds: 15), () {
      loadAd();
    });
  }

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Load an [AppOpenAd].
  void loadAd() {
    AppOpenAd.load(
      adUnitId: HuuuaConfig.instance.getAdmobBannerId(admob_type.admob_splash),
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (loadAdError) {
          // Gets the domain from which the error came.
          String domain = loadAdError.domain;

          // Gets the error code. See
          // https://developers.google.com/android/reference/com/google/android/gms/ads/AdRequest
          // and https://developers.google.com/admob/ios/api/reference/Enums/GADErrorCode
          // for a list of possible codes.
          int code = loadAdError.code;

          // A log friendly string summarizing the error.
          String message = loadAdError.message;

          // Get response information, which may include results of mediation requests.
          ResponseInfo? responseInfo =
              loadAdError.responseInfo; // Handle the error.
          print('AppOpenAd failed to load: $responseInfo');
          print('AppOpenAd failed to load: $loadAdError');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    // if (Get.currentRoute == Routes.LoginView) {
    //   //指定页面不弹出全屏广告
    //   return;
    // }

    if (!isAdAvailable) {
      print('Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad.');
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      print('Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    if (_appOpenAd!.fullScreenContentCallback == null) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          print('$ad onAdShowedFullScreenContent');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('$ad onAdFailedToShowFullScreenContent: $error');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
        },
        onAdDismissedFullScreenContent: (ad) {
          print('$ad onAdDismissedFullScreenContent');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAd();
        },
      );
    }

    // 获取当前时间
    DateTime currentTime = DateTime.now();

    // 计算时间差
    Duration duration = currentTime.difference(this.lastShowTime);

    // 如果时间差小于十分钟，则不执行函数体
    if (duration < Duration(minutes: 10)) {
      print("函数调用太频繁，请等待至少十分钟后再试。");
      return;
    }

    // 如果时间差大于或等于十分钟，则执行函数体
    print("函数执行成功，当前时间：${currentTime.toString()}");

    // 更新上次调用时间
    this.lastShowTime = currentTime;

    _appOpenAd!.show();
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }
}

//后台返回弹出
class AppLifecycleReactor extends WidgetsBindingObserver {
  final AdManagerSplash appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Try to show an app open ad if the app is being resumed and
    // we're not already showing an app open ad.
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAdIfAvailable();
    }
  }
}
