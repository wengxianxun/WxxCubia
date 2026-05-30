import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/dialog/revive_dialog/ad_revive_cell.dart';
import 'package:wxx_cubia/util/dialog/revive_dialog/life_revive_cell.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';
import 'package:wxx_cubia/util/item_widget.dart';

// 改为StatefulWidget，确保UI能正确更新
class ReviveDialog extends StatefulWidget {
  const ReviveDialog({super.key, required this.onRestart});
  final VoidCallback onRestart;

  /// ✅ 静态方法，直接调用即可
  static void show({
    required VoidCallback onRestart,
    required VoidCallback onCancel,
  }) {
    HuuuaDialog.show(
      childWidget: ReviveDialog(onRestart: onRestart),
      title: 'Revive'.tr,
      cancelTitle: 'close'.tr, // 使用国际化翻译
      onCancel: onCancel,
    );
  }

  @override
  State<ReviveDialog> createState() => _RefreshGetDialogState();
}

class _RefreshGetDialogState extends State<ReviveDialog> {
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
              LifeReviveCell(
                onRestart: () {
                  HuuuaDialog.hide();
                  widget.onRestart();
                },
              ),
              SizedBox(height: 8),
              AdReviveCell(
                onRestart: () {
                  HuuuaDialog.hide();
                  widget.onRestart();
                },
                onAdClose: () {},
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
            "My Lives".tr,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
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
