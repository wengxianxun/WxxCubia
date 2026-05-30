import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/in_app_purchase/in_app_purchase_service.dart';
import 'package:wxx_cubia/util/item_plus_widget.dart';

class IapCell extends StatefulWidget {
  final Function onRewardClaimed;

  const IapCell({Key? key, required this.onRewardClaimed}) : super(key: key);

  @override
  _IapCellState createState() => _IapCellState();
}

class _IapCellState extends State<IapCell> {
  bool canIap = true;
  String productPrice = "loading".tr; // 默认显示"buy"，初始化完成后更新为价格
  final String productId = "com.wxx.popstar.itembox1";
  final int hummberCount = 5;
  final int penCount = 5;
  final int refreshCount = 5;
  final int lifeCount = 5;
  @override
  void initState() {
    super.initState();
    _initializeIapAndLoadProducts();
  }

  Future<void> _initializeIapAndLoadProducts() async {
    try {
      // 初始化内购管理器并等待完成
      await InAppPurchaseManager().init();

      // 初始化完成后获取商品信息
      final product = InAppPurchaseManager().getProductById(productId);
      if (product != null) {
        print('商品标题: ${product.title}');
        print('商品价格: ${product.price}');

        // 更新商品价格并刷新UI
        if (mounted) {
          setState(() {
            productPrice = product.displayPrice ?? "loading".tr;
          });
        }
      } else {
        print('商品不存在');
      }
    } catch (e) {
      print('初始化内购失败: $e');
    }
  }

  Widget buyBtn() {
    return HuuuaButton(
      icon: Icon(Icons.shopify_rounded, size: 20, color: Colors.white70),
      text: productPrice,
      border: Border.all(color: Colors.orange, width: 2),
      backgroundColor: Colors.green,
      onTap: () {
        SmartDialog.showLoading();
        _handlePurchase();
      },
    );
  }

  void _handlePurchase() {
    InAppPurchaseManager().purchaseProduct(
      productId,
      callback: (String productId, bool success, String? errorMessage) {
        if (success) {
          print('购买成功: $productId');
          GameDataManager().addRefreshCount(refreshCount);
          GameDataManager().addPenCount(penCount);
          GameDataManager().addHammerCount(hummberCount);
          GameDataManager().addLifeCount(lifeCount);
          // 购买成功后的回调
          widget.onRewardClaimed();
        } else {
          print('购买失败: $errorMessage');

          SmartDialog.dismiss();

          SmartDialog.showToast(errorMessage ?? 'error');
          // 可以在这里显示错误提示
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
                title: "+$refreshCount",
                imgPath: "assets/images/btn/refresh.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$hummberCount",
                imgPath: "assets/images/btn/chuizi.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$penCount",
                imgPath: "assets/images/btn/pen.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$lifeCount",
                imgPath: "assets/images/btn/life.png",
              ),
              Spacer(),
              buyBtn(),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Buy to Get Lots of Items".tr,
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
          // SizedBox(height: 6),
        ],
      ),
    );
  }
}
