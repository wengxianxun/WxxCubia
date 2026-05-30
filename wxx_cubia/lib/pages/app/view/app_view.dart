import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:wxx_flutter_rank_package/widget/rank_icon_button.dart';
import 'package:wxx_cubia/pages/app/app_controller.dart';
import 'package:wxx_cubia/pages/app/view/child/app_lunch_view.dart';
import 'package:wxx_cubia/pages/game_service/view/game_service_rank_view.dart';
import 'package:wxx_cubia/util/ad/home_banner.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

class AppView extends GetView<AppController> {
  // final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      id: "AppView",
      init: controller,
      builder: (value) {
        return bodyView();
      },
    );
  }

  Widget bodyView() {
    if (controller.netType.value == NetType.yesNet) {
      return mainView();
    } else {
      return launchView();
    }
  }

  Widget launchView() {
    return AppLunchView(
      appController: controller,
      onOpenCallBack: () {
        //隐藏lunch,打开小说tab界面
        // controller.openView();
      },
    );
  }

  Widget mainView() {
    return Scaffold(
      extendBody: false,
      // resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GameWidget(
            game: controller.game,
            overlayBuilderMap: {
              // 'RankButton': (context, game) {
              //   if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
              //     return Container();
              //   }
              //   return Positioned(
              //     left: 30,
              //     bottom: 30, // 如果广告加载了，调整按钮位置
              //     child: RankIconButton(
              //       onPressed: () {
              //         // SoundPool().playButton();
              //         // Get.toNamed(
              //         //   RankRoutes.RankView,
              //         //   arguments: {'score_type': GameModeType.classic.value},
              //         // );
              //       },
              //     ),
              //   );
              // },
              const_PlayerView: (context, game) {
                if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
                  return Container();
                }
                return Positioned(
                  left: 30,
                  bottom: 30, // 如果广告加载了，调整按钮位置
                  child: GameServiceRankView(),
                );
              },

              const_HomeBanner: (context, game) {
                return Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: HomeBanner(),
                );
              },

              // 'NativeAd': (context, game) {
              //   if (!HuuuaConfig.isDebug) {
              //     return Positioned(
              //       top: 50,
              //       left: 0,
              //       right: 0,
              //       child: Obx(() {
              //         return (controller.isNativeAdLoaded.value &&
              //                 controller.nativeAd != null)
              //             ? Container(
              //                 height: 120, // 根据你的原生广告模板设置合适的高度
              //                 width: double.infinity, // 宽度通常设置为撑满
              //                 alignment: Alignment.center,
              //                 child: AdWidget(ad: controller.nativeAd!),
              //               )
              //             : Container();
              //       }),
              //     );
              //   } else {
              //     return SizedBox.shrink();
              //   }
              // },
            },
            // initialActiveOverlays: const ['RankButton', 'NativeAd'],
          ),
        ],
      ),
    );
  }
}
