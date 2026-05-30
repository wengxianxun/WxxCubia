import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加这行导入
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:wxx_flutter_rank_package/base/rank_manager.dart';
import 'package:wxx_cubia/pages/game_service/game_service_controller.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/routes/app_pages.dart';
import 'package:wxx_cubia/util/ad/admob/ad_consent_manager.dart';
import 'package:wxx_cubia/util/ad/admob/ad_manager_splash.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util/huuua_logger.dart';
import 'package:wxx_cubia/util/huuua_translate.dart';
import 'package:wxx_cubia/util_flame/audio_controller.dart';

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyApp> with WidgetsBindingObserver {
  var _isMobileAdsInitializeCalled = false;
  var _isPrivacyOptionsRequired = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initApp();

    if (HuuuaConfig.instance.flavorstype == flavors_type.taptap &&
        HuuuaConfig.instance.agreeService) {
      initAdmob();
    }
  }

  void initAdmob() {
    ConsentManager.instance.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        // Consent not obtained in current session.
        debugPrint(
          "${consentGatheringError.errorCode}: ${consentGatheringError.message}",
        );
      }

      // Check if a privacy options entry point is required.
      _getIsPrivacyOptionsRequired();

      // Attempt to initialize the Mobile Ads SDK.
      _initializeMobileAdsSDK();
    });
    // This sample attempts to load ads using consent obtained in the previous session.
    _initializeMobileAdsSDK();
  }

  void _getIsPrivacyOptionsRequired() async {
    if (await ConsentManager.instance.isPrivacyOptionsRequired()) {
      setState(() {
        _isPrivacyOptionsRequired = true;
      });
    } else {
      // devLog("NO");
    }
  }

  void _initializeMobileAdsSDK() async {
    if (_isMobileAdsInitializeCalled) {
      return;
    }

    if (await ConsentManager.instance.canRequestAds()) {
      _isMobileAdsInitializeCalled = true;

      // Initialize the Mobile Ads SDK.
      MobileAds.instance.initialize();

      AdManagerSplash.instance.defaultInit(); //开屏
      WidgetsBinding.instance.addObserver(
        AppLifecycleReactor(appOpenAdManager: AdManagerSplash.instance),
      ); //后台注册
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void initApp() {
    // 应用启动后在后台线程处理耗时操作
    Future.microtask(() async {
      // 并行执行初始化任务
      await Future.wait([
        // 加载历史分数
        gameDataManager.loadHistoryScore(),
      ]);

      // 移除启动画面
      FlutterNativeSplash.remove();
    });
    // 立即执行的必要初始化
    AudioController.loadMuteState();
    AudioController.loadBGMState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        print("paused");
        // 应用进入后台时记录玩家退出

        break;
      case AppLifecycleState.inactive:
        print("inactive");
        // 应用失去焦点时记录玩家退出

        break;
      case AppLifecycleState.detached:
        print("detached");
        // 应用分离时记录玩家退出

        break;
      case AppLifecycleState.hidden:
        print("hidden");
        // 应用隐藏时记录玩家退出

        break;
      case AppLifecycleState.resumed:
        print("resumed");
        // 应用恢复前台时取消离线提醒

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return GetMaterialApp(
          translations: HuuuaTranslate(),
          locale: PlatformDispatcher.instance.locale,
          // locale: Locale('en', 'US'), // 强制使用英文作为默认语言
          fallbackLocale: Locale('en', 'US'), // 添加后备语言设置
          debugShowCheckedModeBanner: false,
          enableLog: true,
          navigatorObservers: [FlutterSmartDialog.observer],
          builder: (context, child) {
            // 将状态栏样式设置整合到应用的构建器中
            SystemChrome.setSystemUIOverlayStyle(
              const SystemUiOverlayStyle(
                statusBarColor: Colors.black, // 黑色背景
                statusBarIconBrightness: Brightness.light, // Android: 白色图标
                statusBarBrightness: Brightness.dark, // iOS: 白色图标/文字
              ),
            );
            return FlutterSmartDialog.init()(context, child);
          },
          logWriterCallback: Logger.write,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,

          onInit: () {
            // RankManager.lazyput();

            // 注册 GameServiceController
            Get.put(GameServiceController());
            // 可选：预热 Google 服务
            Get.find<GameServiceController>().prewarmGoogleServices();
          },
          routingCallback: (routing) {},
        );
      },
    );
  }
}
