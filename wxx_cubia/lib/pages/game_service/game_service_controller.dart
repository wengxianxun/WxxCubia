import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:games_services/games_services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';

class GameServiceController extends GetxController {
  final _lastReportTime = 0.obs;
  final _isSigningIn = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    GameAuth.isSignedIn.then((value) {
      if (value) {
        _isSigningIn.value = true;
        tryUploadScore();
      } else {
        _isSigningIn.value = false;
      }
    });
  }

  /// 自动尝试登录（关键）
  Future<void> _trySignIn() async {
    try {
      final result = await GameAuth.signIn();
      print(result);
    } catch (e) {
    } finally {}
  }

  /// 检查 Google 服务是否可访问
  Future<bool> isGoogleServiceAvailable() async {
    if (Platform.isIOS) {
      return true;
    }
    try {
      // 1. 先检查基本网络连接
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("无网络连接");
        return false;
      }

      // 2. 使用 http 包主动探测 Google 服务
      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(Duration(seconds: 6));

      return response.statusCode == 200;
    } catch (e) {
      print("Google 服务不可访问: $e");
      return false;
    }
  }

  /// 上报分数（带前置检查）
  Future<void> tryUploadScore() async {
    final historyScore = gameDataManager.getHistoryScore();
    if (_isSigningIn.value) {
      try {
        await GamesServices.submitScore(
          score: Score(
            iOSLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
            androidLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
            value: historyScore,
          ),
        );
        print("分数上报成功");
      } catch (e) {
        print("提交分数失败: $e");
      }

      _lastReportTime.value = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// App 启动时预热（可选）
  Future<void> prewarmGoogleServices() async {
    final isAvailable = await isGoogleServiceAvailable();
    if (isAvailable) {
      _trySignIn();
      print("Google 服务预热完成");
    }
  }

  Future<void> openLeaderboard() async {
    final isAvailable = await isGoogleServiceAvailable();
    if (isAvailable) {
      try {
        tryUploadScore();
        String? result = await GamesServices.showLeaderboards(
          iOSLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
          androidLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
        );

        print("${result}");
      } catch (e) {
        HuuuaDialog.show(
          title: "Tips".tr,
          message:
              '${"Cannot connect to Google Play leaderboards at this time.".tr} - ${e.toString()}',
        );
        //提示
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(const SnackBar(content: Text('当前设备不支持排行榜')));
      }
    } else {
      HuuuaDialog.show(
        title: "Tips".tr,
        message: "Cannot connect to Google Play leaderboards at this time.".tr,
      );
    }
  }
}
