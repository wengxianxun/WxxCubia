import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:games_services/games_services.dart';
import 'package:get/get.dart';
import 'package:wxx_flutter_rank_package/widget/rank_icon_button.dart';
import 'package:wxx_cubia/pages/game_service/game_service_controller.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

class GameServiceRankView extends GetView {
  final GameServiceController gamecontroller = GameServiceController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      id: "GameServiceRankView",
      init: gamecontroller,
      builder: (value) {
        return bodyView();
      },
    );
  }

  Widget bodyView() {
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
              onPressed: () async {
                SmartDialog.showLoading();
                SoundPool().playButton();
                await gamecontroller.openLeaderboard();
                SmartDialog.dismiss();
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
