// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/jieqi_calculator.dart';
import 'screens/jieqi_home_screen.dart';
import 'utils/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService.initialize();

  _requestNotificationPermission();

  // 强制竖屏模式
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 初始化节气计算工具
  await JieQiCalculator.initSweph();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '二十四节气',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const JieQiHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
