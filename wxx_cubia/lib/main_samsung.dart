import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加这行导入
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wxx_cubia/my_app.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

// 在main函数中添加预加载广告的代码
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HuuuaConfig.instance.setFlavorsType(flavors_type.samsung);
  // 确保只设置一次状态栏模式
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  // 初始化基本配置
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  // 启动应用
  runApp(MyApp());
}
