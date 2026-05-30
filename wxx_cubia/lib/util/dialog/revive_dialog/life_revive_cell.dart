import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/item_plus_widget.dart';

class LifeReviveCell extends StatefulWidget {
  final Function onRestart;

  const LifeReviveCell({Key? key, required this.onRestart}) : super(key: key);

  @override
  _FreeCellState createState() => _FreeCellState();
}

class _FreeCellState extends State<LifeReviveCell> {
  bool canLifeRevive = false;

  @override
  void initState() {
    super.initState();
    // 检查是否还有生命可以复活
    _checkCanGetFree();
  }

  void _checkCanGetFree() {
    // 检查是否还有生命
    canLifeRevive = GameDataManager().canLifeRevive();
    if (!GameDataManager().isInitialized) {
      // 如果未初始化，延迟检查
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            canLifeRevive = GameDataManager().canLifeRevive();
          });
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget useBtn() {
    return HuuuaButton(
      icon: Icon(Icons.start_rounded, size: 20, color: Colors.white70),
      text: canLifeRevive ? "Revive".tr : "No lives left".tr,
      backgroundColor: canLifeRevive ? Colors.green : Colors.grey,
      onTap: () {
        if (canLifeRevive) {
          canLifeRevive = false;

          GameDataManager().reduceLifeCount(); //减少一个生命

          // 调用回调，重新开始游戏
          widget.onRestart();
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
                title: "-1",
                imgPath: "assets/images/btn/life.png",
              ),

              Spacer(),
              useBtn(),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "使用一颗生命之心可以复活当前关卡".tr,
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
