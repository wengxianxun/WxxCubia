import 'dart:io';

import 'package:get/get_utils/src/platform/platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameModeType {
  classic("classic", 0);

  const GameModeType(this.value, this.number);
  final String value;
  final int number;
}

/// 道具类型枚举
enum ItemType {
  hammer("hammer", 0),
  refresh("refresh", 1),
  pen("pen", 2);

  const ItemType(this.value, this.number);
  final String value;
  final int number;
}

const bool inProduction = const bool.fromEnvironment("dart.vm.product");

enum flavors_type {
  taptap("taptap", 0),
  google("google", 1),
  samsung("samsung", 2),
  apple("apple", 3),
  google_candy("google_candy", 4),
  google_cubeflow("google_cubeflow", 5);

  const flavors_type(this.value, this.number);
  final String value;
  final int number;
}

enum admob_type {
  admob_native, //设置banner
  admob_refresh_times_rewarded, //刷新次数激励广告
  admob_splash, //开屏
}

const String AGREEServicekey = 'agreeService';
const String const_HomeBanner = "HomeBanner";
const String const_PlayerView = "PlayerView";
const String const_RankButton = "RankButton";

class HuuuaConfig {
  static HuuuaConfig _config = HuuuaConfig();
  static HuuuaConfig get instance => getInstance();
  late final flavors_type flavorstype;

  static final showAd = true;
  // 在debug模式下可修改，但在release模式下始终为false
  static bool _isDebug = true;

  static bool get isDebug {
    // 在release模式下，强制返回false
    if (inProduction) {
      return false;
    }
    return _isDebug;
  }

  //获取单例
  static HuuuaConfig getInstance() {
    _config ??= HuuuaConfig();
    return _config;
  }

  void setFlavorsType(flavors_type type) {
    flavorstype = type;
  }

  String getImagePath() {
    if (flavorstype == flavors_type.google_candy) {
      return 'candy';
    } else {
      return 'star';
    }
  }

  // 获取排行榜id
  String getLeaderboardID() {
    if (Platform.isAndroid) {
      // android
      return "CgkIr8qC1JoPEAIQAQ";
    } else {
      //ios
      return "highscore";
    }
  }

  //发送事件
  String getAdmobBannerId(admob_type type) {
    if (inProduction) {
      if (HuuuaConfig.instance.flavorstype == flavors_type.apple ||
          HuuuaConfig.instance.flavorstype == flavors_type.samsung ||
          HuuuaConfig.instance.flavorstype == flavors_type.google ||
          HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
        /// 正式
        switch (type) {
          case admob_type.admob_native:
            return GetPlatform.isAndroid
                ? 'ca-app-pub-5914587552835750/9651138970'
                : 'ca-app-pub-5914587552835750/5407850329';
            break;
          case admob_type.admob_refresh_times_rewarded:
            return GetPlatform.isAndroid
                ? 'ca-app-pub-5914587552835750/9528575732'
                : 'ca-app-pub-5914587552835750/5599422016';
            break;
          case admob_type.admob_splash:
            return GetPlatform.isAndroid
                ? 'ca-app-pub-5914587552835750/1664083418'
                : 'ca-app-pub-5914587552835750~3245270155';
            break;
        }
      }
    } else {
      /// 测试id
      switch (type) {
        case admob_type.admob_native:
          return GetPlatform.isAndroid
              ? 'ca-app-pub-3940256099942544/2247696110'
              : 'ca-app-pub-3940256099942544/3986624511';
          break;
        case admob_type.admob_refresh_times_rewarded:
          return GetPlatform.isAndroid
              ? 'ca-app-pub-3940256099942544/5224354917'
              : 'ca-app-pub-3940256099942544/1712485313';
          break;
        case admob_type.admob_splash:
          return GetPlatform.isAndroid
              ? 'ca-app-pub-3940256099942544/5575463023'
              : 'ca-app-pub-3940256099942544/5575463023';
          break;
      }
    }
    return "";
  }

  ///枚举类型转string
  String enumToString(o) => o.toString().split('.').last;

  ///string转枚举类型
  T enumFromString<T>(Iterable<T> values, String value) {
    // ,orElse: () => null
    return values.firstWhere(
      (type) => type.toString().split('.').last == value,
    );
  }

  bool agreeService = false;

  Future<bool> checkAgreeService() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    var v = sharedPreferences.getBool(AGREEServicekey);
    if (v == null || v == "") {
      return false;
    }
    agreeService = v;
    return agreeService;
  }

  Future<void> saveAgreeService(bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool(AGREEServicekey, value);
  }
}
