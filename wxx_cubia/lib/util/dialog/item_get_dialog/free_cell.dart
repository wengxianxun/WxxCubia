import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/item_plus_widget.dart';

class FreeCell extends StatefulWidget {
  final Function onRewardClaimed;

  const FreeCell({Key? key, required this.onRewardClaimed}) : super(key: key);

  @override
  _FreeCellState createState() => _FreeCellState();
}

class _FreeCellState extends State<FreeCell> {
  bool canGetFree = false;

  @override
  void initState() {
    super.initState();
    // 检查是否可以领取每日免费道具
    _checkCanGetFree();
  }

  void _checkCanGetFree() {
    // 检查是否今天已经领取过
    canGetFree = GameDataManager().canGetFreeRefresh();
    if (!GameDataManager().isInitialized) {
      // 如果未初始化，延迟检查
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            canGetFree = GameDataManager().canGetFreeRefresh();
          });
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget freeBtn() {
    return HuuuaButton(
      icon: Icon(Icons.gpp_good_rounded, size: 20, color: Colors.white70),
      text: canGetFree ? "free_claim".tr : "try_tomorrow".tr,
      backgroundColor: canGetFree ? Colors.green : Colors.grey,
      onTap: () {
        if (canGetFree) {
          canGetFree = false;
          // 领取每日免费次数
          GameDataManager().claimTodayFree();

          // 调用回调，通知奖励已领取
          widget.onRewardClaimed();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white54,
        border: Border(
          bottom: BorderSide(color: Colors.black54, width: 0.67),
          top: BorderSide(color: Colors.black54, width: 0.67),
        ),
      ),
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemPlusWidget(
                title: "+1",
                imgPath: "assets/images/btn/refresh.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+1",
                imgPath: "assets/images/btn/chuizi.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(title: "+1", imgPath: "assets/images/btn/pen.png"),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+1",
                imgPath: "assets/images/btn/life.png",
              ),
              Spacer(),
              freeBtn(),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      "Claim your free items every day and make your adventure easier!"
                          .tr,
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
