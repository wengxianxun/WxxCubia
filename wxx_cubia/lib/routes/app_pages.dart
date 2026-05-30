import 'package:get/get.dart';
// import 'package:wxx_flutter_rank_package/flutter_package_rank.dart';
// import 'package:wxx_flutter_rank_package/pages/rank/rank_binding.dart';
// import 'package:wxx_flutter_rank_package/routes/rank_pages.dart';
import 'package:wxx_cubia/pages/app/app_binding.dart';
import 'package:wxx_cubia/pages/app/view/app_view.dart';
import 'package:wxx_cubia/pages/app_webview/app_webview_binding.dart';
import 'package:wxx_cubia/pages/app_webview/view/app_webview_view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.AppView;

  static final routes = [
    GetPage(name: Routes.AppView, page: () => AppView(), binding: AppBinding()),
    // 排行榜页面加入项目路由
    // GetPage(
    //   name: RankRoutes.RankView,
    //   page: () => RankView(),
    //   binding: RankBinding(),
    // ),
    GetPage(
      name: Routes.AppWebviewView,
      page: () => AppWebviewView(),
      binding: AppWebviewBinding(),
    ),
  ];
}
