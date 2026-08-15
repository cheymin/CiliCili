import 'dart:async';
import 'package:PiliPlus/common/init.dart';
import 'package:PiliPlus/common/widgets/scale_app.dart';
import 'package:PiliPlus/router/app_pages.dart';
import 'package:PiliPlus/utils/global_error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // 初始化全局错误处理
  initGlobalErrorHandler();
  
  final bindings = ScaledWidgetsFlutterBinding.ensureInitialized();
  await initApp(bindings);
  
  WidgetsFlutterBinding.ensureInitialized();
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    title: 'cilicili',
    minimumSize: Size(380, 650),
    size: Size(380, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.setPreventClose(true);
  });
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // 延迟初始化路由，确保全局错误处理已启动
  await Future.delayed(const Duration(milliseconds: 100));
  
  runApp(
    GetMaterialApp(
      title: "cilicili",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: Routes.getPages,
      navigatorKey: Get.key,
      builder: (context, child) {
        return FlutterSmartDialog(
          child: child!,
          interceptors: [
            CustomSmartDialogInterceptor(),
          ],
        );
      },
    ),
  );
}

class CustomSmartDialogInterceptor extends SmartDialogInterceptor {
  @override
  Future<bool> onDismiss(SmartDialogLayer layer) async {
    if (layer == SmartDialogLayer.mask) {
      return await windowManager.isPreventClose();
    }
    return true;
  }
}
