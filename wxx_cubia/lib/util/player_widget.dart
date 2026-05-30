import 'package:flutter/material.dart';
import 'package:games_services/games_services.dart';
import 'package:wxx_flutter_rank_package/widget/rank_icon_button.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({super.key});

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  @override
  void initState() {
    super.initState();
  }

  /// 打开排行榜（带容错）
  Future<void> _openLeaderboard() async {
    try {
      String? result = await GamesServices.showLeaderboards(
        iOSLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
        androidLeaderboardID: HuuuaConfig.instance.getLeaderboardID(),
      );

      print("${result}");
    } catch (e) {
      // fallback：你自己的排行榜
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前设备不支持排行榜')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerData?>(
      stream: GameAuth.player,
      builder: (context, snapshot) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (snapshot.hasData && snapshot.data != null)
              Text(
                '${snapshot.data!.displayName ?? ""}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            const SizedBox(height: 8),

            /// 🏆 排行榜按钮
            RankIconButton(
              onPressed: () {
                SoundPool().playButton();
                _openLeaderboard();
                // Get.toNamed(
                //   RankRoutes.RankView,
                //   arguments: {'score_type': GameModeType.classic.value},
                // );
              },
            ),
          ],
        );

        /// 1️⃣ 加载中
        // if (snapshot.connectionState == ConnectionState.waiting ||
        //     _isSigningIn) {
        //   return Container(
        //     child: LoadingAnimationWidget.threeArchedCircle(
        //       color: Colors.white70,
        //       size: 40,
        //     ),
        //   );
        // }
        //
        // /// 2️⃣ 登录失败（设备不支持）
        // if (_error != null) {
        //   return HuuuaButton(
        //     icon: Icon(Icons.people, size: 25),
        //     text: "Login failed".tr,
        //     backgroundColor: Colors.red,
        //     onTap: () {},
        //   );
        // }
        //
        // /// 3️⃣ 已登录
        // if (snapshot.hasData && snapshot.data != null) {
        //   final player = snapshot.data!;
        //
        //
        // }
        //
        // /// 4️⃣ 未登录（可手动触发）
        // return Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     ElevatedButton(
        //       onPressed: _trySignIn,
        //       child: const Text('Game Center'),
        //     ),
        //   ],
        // );
      },
    );
  }
}
