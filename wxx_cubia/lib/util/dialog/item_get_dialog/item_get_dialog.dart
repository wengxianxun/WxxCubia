import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/ad_cell.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/free_cell.dart';
import 'package:wxx_cubia/util/dialog/item_get_dialog/iap_cell.dart';
import 'package:wxx_cubia/util/huuua_config.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';
import 'package:wxx_cubia/util/item_widget.dart';
import 'package:wxx_cubia/util_flame/sound_pool.dart';

// 改为StatefulWidget，确保UI能正确更新
class ItemGetDialog extends StatefulWidget {
  const ItemGetDialog({super.key, required this.onRewardClaimed});

  final VoidCallback onRewardClaimed;

  /// ✅ 静态方法，直接调用即可
  static void show({
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required VoidCallback onRewardClaimed,
  }) {
    HuuuaDialog.show(
      childWidget: ItemGetDialog(onRewardClaimed: onRewardClaimed),
      title: 'Get Free Items'.tr,
      cancelTitle: 'close'.tr, // 使用国际化翻译
      onCancel: onCancel,
    );
  }

  @override
  State<ItemGetDialog> createState() => _RefreshGetDialogState();
}

class _RefreshGetDialogState extends State<ItemGetDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 1.激励广告奖励 2.免费领取 3.购买
    return Container(
      constraints: BoxConstraints(
        maxHeight:
            Get.height -
            (Get.mediaQuery.padding.bottom + 77 + Get.mediaQuery.padding.top),
      ),
      child: RawScrollbar(
        thumbColor: Colors.blue, // 滑块颜色
        trackColor: Colors.grey[200], // 轨道颜色
        trackBorderColor: Colors.grey, // 轨道边框颜色
        thickness: 10,
        radius: Radius.circular(5),
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
              myCell(),
              SizedBox(height: 8),
              adCell(),
              SizedBox(height: 8),
              freeCell(),
              SizedBox(height: 8),
              iapCell(),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget iapCell() {
    if (HuuuaConfig.instance.flavorstype == flavors_type.samsung) {
      return SizedBox.shrink();
    }
    return IapCell(
      onRewardClaimed: () {
        Future.delayed(Duration(milliseconds: 300), () {
          SmartDialog.dismiss();

          // 更新状态，防止再次领取
          if (mounted) {
            setState(() {
              SoundPool().playBubble();
            });
          }
        });
        SmartDialog.showToast(
          'claim_refresh_success'.tr,
          alignment: Alignment.center,
        );
        widget.onRewardClaimed();
      },
    );
  }

  Widget freeCell() {
    return FreeCell(
      onRewardClaimed: () {
        Future.delayed(Duration(milliseconds: 300), () {
          // 更新状态，防止再次领取
          if (mounted) {
            setState(() {
              SoundPool().playBubble();
            });
          }
        });
        widget.onRewardClaimed();
      },
    );
  }

  Widget adCell() {
    return AdCell(
      onRewardClaimed: () {
        widget.onRewardClaimed();
      },
      onAdClose: () {
        SmartDialog.showToast("claim_refresh_success".tr);
        Future.delayed(Duration(milliseconds: 300), () {
          setState(() {
            SoundPool().playBubble();
          });
        });
      },
    );
  }

  Widget myCell() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white70,
        border: Border(
          bottom: BorderSide(color: Colors.black54, width: 0.67),
          top: BorderSide(color: Colors.black54, width: 0.67),
        ),
      ),
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Items".tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              ItemWidget(
                number: GameDataManager().refreshCount,
                imgPath: "assets/images/btn/refresh.png",
              ),
              SizedBox(width: 5),
              ItemWidget(
                number: GameDataManager().hammerCount,
                imgPath: "assets/images/btn/chuizi.png",
              ),
              SizedBox(width: 5),
              ItemWidget(
                number: GameDataManager().penCount,
                imgPath: "assets/images/btn/pen.png",
              ),
              SizedBox(width: 5),
              ItemWidget(
                number: GameDataManager().lifeCount,
                imgPath: "assets/images/btn/life.png",
              ),
              Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 清理广告资源
    // _adManager.dispose();
    // _cancelCountdownTimer(); // 使用新的取消方法
    super.dispose();
  }
}
