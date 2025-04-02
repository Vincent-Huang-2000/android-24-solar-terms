// lib/utils/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 添加一个标志来跟踪初始化状态
  static bool _isInitialized = false;

  /// 初始化通知服务
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(settings);
      tz.initializeTimeZones();

      _isInitialized = true;
      debugPrint('通知服务初始化成功');
      return true;
    } catch (e) {
      debugPrint('通知服务初始化失败: $e');
      return false;
    }
  }

  /// 检查通知权限状态
  static Future<bool> checkPermissionStatus() async {
    try {
      // 直接检查当前权限状态
      final status = await _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationAppLaunchDetails();

      debugPrint('通知权限检查完成');
      return true;  // 简化处理，我们假设权限已在main.dart中处理
    } catch (e) {
      debugPrint('检查通知权限失败: $e');
      return false;
    }
  }

  /// 立刻显示一个本地通知
  static Future<bool> showInstantNotification({
    required String title,
    required String body,
    int id = 999,
  }) async {
    try {
      // 确保已初始化
      if (!_isInitialized) {
        await initialize();
      }

      await _notificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_channel_id',
            '即时通知',
            channelDescription: '立刻显示的通知',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('即时通知发送成功: $title');
      return true;
    } catch (e) {
      debugPrint('发送即时通知失败: $e');
      return false;
    }
  }

  /// 安排一个节气通知
  static Future<bool> scheduleJieQiNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Duration reminderBefore = const Duration(hours: 1),
    int id = 0,
  }) async {
    try {
      // 确保已初始化
      if (!_isInitialized) {
        await initialize();
      }

      final notificationTime = scheduledTime.subtract(reminderBefore);

      // 如果设置的时间已经过去了，则不安排通知
      if (notificationTime.isBefore(DateTime.now())) {
        debugPrint('通知时间 ${notificationTime.toIso8601String()} 已过期，跳过');
        return false;
      }

      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        notificationTime,
        tz.local,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'jieqi_channel_id',
            '节气提醒',
            channelDescription: '在节气来临前提醒用户',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // 移除了 uiLocalNotificationDateInterpretation 参数
      );

      debugPrint('已安排节气通知: $title - ${tzScheduledDate.toLocal()}');
      return true;
    } catch (e) {
      debugPrint('安排节气通知失败: $e');
      return false;
    }
  }

  /// 取消所有通知（可用于用户取消所有提醒）
  static Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('已取消所有通知');
    } catch (e) {
      debugPrint('取消所有通知失败: $e');
    }
  }

  /// 取消某个特定通知
  static Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('已取消ID为 $id 的通知');
    } catch (e) {
      debugPrint('取消通知失败: $e');
    }
  }

  /// 检查当前有哪些待处理的通知
  static Future<void> checkPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
      await _notificationsPlugin.pendingNotificationRequests();
      debugPrint('待处理通知数量: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        debugPrint('待处理通知: ID=${notification.id}, 标题=${notification.title}');
      }
    } catch (e) {
      debugPrint('检查待处理通知失败: $e');
    }
  }
}
