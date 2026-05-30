import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/util/dialog/setting_dialog/bgm_toggle_button.dart';
import 'package:wxx_cubia/util/dialog/setting_dialog/clean_star_toggle_button.dart';
import 'package:wxx_cubia/util/dialog/setting_dialog/setting_cell.dart';
import 'package:wxx_cubia/util/dialog/setting_dialog/sound_toggle_button.dart';
import 'package:wxx_cubia/util/huuua_dialog.dart';

// 改为StatefulWidget，确保UI能正确更新
class SettingDialog extends StatefulWidget {
  const SettingDialog({super.key, required this.onRewardClaimed});

  final VoidCallback onRewardClaimed;

  /// ✅ 静态方法，直接调用即可
  static void show({
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    required VoidCallback onRewardClaimed,
  }) {
    HuuuaDialog.show(
      childWidget: SettingDialog(onRewardClaimed: onRewardClaimed),
      title: 'Setting'.tr,
      cancelTitle: 'close'.tr, // 使用国际化翻译
      onCancel: onCancel,
    );
  }

  @override
  State<SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
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
              SettingCell(
                title: 'Sound Effect'.tr,
                childWidget: SoundToggleButton(),
              ),
              SizedBox(height: 8),
              SettingCell(title: 'BGM'.tr, childWidget: BgmToggleButton()),
              SizedBox(height: 8),

              SettingCell(
                title: 'Elimination Method'.tr,
                childWidget: CleanStarToggleButton(),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
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
