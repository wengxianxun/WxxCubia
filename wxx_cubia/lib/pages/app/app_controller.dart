import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
// import 'package:wxx_flutter_rank_package/base/rank_manager.dart';
import 'package:wxx_cubia/pages/popstar_game/pop_star_game.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

enum NetType { normal, noNet, yesNet }

class AppController extends GetxController {
  AppController();
  late final PopStarGame game;
  var netType = NetType.normal.obs; //网络是否正常

  var isNetloading = false.obs;
  @override
  Future<void> onInit() async {
    super.onInit();
    game = PopStarGame(); // 只创建一次
    // netType.value = NetType.noNet;
    // 使用Future.microtask在事件循环的下一个微任务中加载原生广告
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    updateCheck();
    // 在UI渲染完成后延迟执行网络检查，避免阻塞主线程
  }

  Future<void> updateCheck() async {
    bool isAgree = true;
    if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
      isAgree = await HuuuaConfig.instance.checkAgreeService();
    }
    if (isAgree) {
      Future.microtask(() {
        initApp();

        Future.delayed(const Duration(milliseconds: 300), () {
          checkNet();

          print('AppHomeController onReady....................');
        });
      });
    }
  }

  void initApp() {
    // 应用启动后在后台线程处理耗时操作
    Future.microtask(() async {
      // 并行执行初始化任务
      await Future.wait([
        // 初始化广告SDK
        // MobileAds.instance.initialize(),
      ]);
    });
    // RankManager.setup(app_id: "10004");

    // FlutterTencentad.register(
    //   androidId: '1217157347',
    //   iosId: "1217600445",
    //   debug: true,
    //   personalized: FlutterTencentadPersonalized.show, //是否显示个性化推荐广告
    //   channelId: FlutterTencentadChannel.other, //渠道id
    //   enableCollectAppInstallStatus: false,
    // );

    // 初始化广告SDK（建议添加）
    // AdManagerRewarded().initialize();
    //
    // // 延迟执行非关键初始化，让UI先渲染完成
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   // 延迟预加载广告，避免阻塞主线程
    //   AdManagerRewarded().preloadAllAds();
    // });
  }

  @override
  void onClose() {
    super.onClose();
  }

  void updateAppView() {
    update(['AppView']);
  }

  void checkNet() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    isNetloading.value = true;
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      // I am connected to a mobile network.
      print("蜂窝网络");
      netType.value = NetType.yesNet;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      // I am connected to a wifi network.
      print("wifi连接");
      netType.value = NetType.yesNet;
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      // I am connected to a ethernet network.
      print("以太网");
      netType.value = NetType.noNet;
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      // I am connected to a vpn network.
      // Note for iOS and macOS:
      // There is no separate network interface type for [vpn].
      // It returns [other] on any device (also simulator)
      print("vpn连接");
      netType.value = NetType.noNet;
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      // I am connected to a bluetooth.
      print("蓝牙连接");
      netType.value = NetType.noNet;
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      // I am connected to a network which is not in the above mentioned networks.
      print("未知网络连接");
      netType.value = NetType.noNet;
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // I am not connected to any network.
      print("没有网络");
      netType.value = NetType.noNet;
      update(['AppView']);
    }

    if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
      netType.value = NetType.yesNet;
    }

    Future.delayed(Duration(seconds: 1), () {
      isNetloading.value = netType.value == NetType.yesNet;
      update(['AppView']);
    });
    if (netType.value == NetType.yesNet) {
      updateAppView();
    }
  }
}
