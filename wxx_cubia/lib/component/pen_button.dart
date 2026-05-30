import 'dart:ui';

import 'package:flame/components.dart';
import 'package:get/get_utils/src/extensions/export.dart';
import 'package:wxx_cubia/component/huuua_btn_component.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/item_get_dialog.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

/// 改色笔
class PenButton extends HuuuaBtnComponent {
  // 不再使用本地变量，而是引用GameDataManager中的刷新次数
  final Function() onbtnPressed;

  PenButton({
    required Vector2 position,
    required this.onbtnPressed,
    Vector2? size,
    required VoidCallback onUPdate,
  }) : super(
         imagePath: 'btn/pen.png',
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
      // 播放音效
      SoundPool().playButton();

      // 检查是否有改色笔可用
      if (gameDataManager.penCount > 0) {
        // 执行刷新逻辑并获取结果
        OnTapType onTapType = onbtnPressed();

        // 只有当刷新成功时才扣减次数并更新UI
        // if (onTapType == OnTapType.yes) {
        //   // 使用改色笔
        //   if (gameDataManager.reducePenCount()) {
        //     updateBadge();
        //   }
        // }
      } else {
        HuuuaDialog.show(
          title: "Tips".tr,
          message: "Not enough uses".tr,
          cancelTitle: 'close'.tr,
          confirmTitle: 'Go Get'.tr,
          onConfirm: () {
            HuuuaDialog.hide();
            // 显示获取改色笔的对话框
            ItemGetDialog.show(
              onConfirm: () {},

              onCancel: () {},
              // 传递回调函数，用于在领取奖励后刷新按钮显示
              onRewardClaimed: () {
                onUpdate();
                // 调用updateBadge方法更新显示
                updateBadge();
              },
            );
          },
          onCancel: () {},
        );
      }
    };
  }

  // 覆盖父类的updateBadge方法，使用改色笔数量
  @override
  void updateBadge() {
    setBadgeText(
      gameDataManager.penCount > 0 ? '${gameDataManager.penCount}' : '0',
    );
  }
}
