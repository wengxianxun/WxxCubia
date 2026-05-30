import 'dart:ui';

import 'package:flame/components.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/component/huuua_btn_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/item_get_dialog.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

/// 刷新添加次数按钮（带次数限制 + 红点角标）
class RefreshButton extends HuuuaBtnComponent {
  // 不再使用本地变量，而是引用GameDataManager中的刷新次数
  final Function() onbtnPressed;

  RefreshButton({
    required Vector2 position,
    required this.onbtnPressed,
    Vector2? size,
    required VoidCallback onUPdate,
  }) : super(
         imagePath: 'btn/refresh.png',
         onPressed: () {
           return true;
         }, // 我们会在onMount中覆盖逻辑
         position: position,
         size: size ?? Vector2(45, 45),
         anchor: Anchor.center,
         onUpdate: onUPdate,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onMount() {
    super.onMount();

    // 按钮点击逻辑
    button.onTap = () {
      // // 播放音效
      // SoundPool().playButton();
      // RefreshGetDialog.show(
      //   onConfirm: () {},
      //   onCancel: () {},
      //   // 传递回调函数，用于在领取奖励后刷新按钮显示
      //   onRewardClaimed: () {
      //     // 调用updateBadge方法更新显示
      //     updateBadge();
      //   },
      // );
      // 播放音效
      SoundPool().playButton();
      if (gameDataManager.refreshCount <= 0) {
        //提示刷新次数不够，获取方式弹窗
        HuuuaDialog.show(
          title: "Tips".tr,
          message: "Not enough uses".tr,
          cancelTitle: 'close'.tr,
          confirmTitle: 'Go Get'.tr,
          onConfirm: () {
            HuuuaDialog.hide();
            ItemGetDialog.show(
              onConfirm: () {},
              onCancel: () {},

              // 传递回调函数，用于在领取奖励后刷新按钮显示
              onRewardClaimed: () {
                // 调用RefreshButton的_updateBadge方法更新显示
                onUpdate();
                updateBadge();
              },
            );
          },
          onCancel: () {},
        );
      } else {
        // 执行刷新逻辑并获取结果
        bool refreshSuccess = onbtnPressed();

        // 只有当刷新成功时才扣减次数并更新UI
        if (refreshSuccess) {
          if (gameDataManager.reduceRefreshCount()) {
            updateBadge();
          }
        }
      }
    };
  }

  // 覆盖父类的updateBadge方法，确保显示正确的刷新次数
  @override
  void updateBadge() {
    setBadgeText(
      gameDataManager.refreshCount > 0
          ? '${gameDataManager.refreshCount}'
          : '0',
    );
  }
}
