// lib/screens/jieqi_home_screen.dart
import 'package:flutter/material.dart';
import '../models/jieqi_model.dart';
import '../utils/jieqi_calculator.dart';
import '../widgets/jieqi_card.dart';
import '../widgets/jieqi_list_item.dart';
import '../utils/notification_service.dart';

class JieQiHomePage extends StatefulWidget {
  const JieQiHomePage({Key? key}) : super(key: key);

  @override
  _JieQiHomePageState createState() => _JieQiHomePageState();
}

class _JieQiHomePageState extends State<JieQiHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<JieQi>> _jieQiListFuture;
  late Future<JieQi?> _currentJieQiFuture;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJieQiData();
  }

  Future<void> _loadJieQiData() async {
    _jieQiListFuture = JieQiCalculator.getJieQiList(_selectedYear);
    _currentJieQiFuture = JieQiCalculator.getCurrentJieQi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('二十四节气'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '当前节气'),
            Tab(text: '全年节气'),
          ],
        ),
        actions: [
// 在AppBar的actions中修改
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: '测试通知',
            onPressed: () async {
              // 显示加载指示器
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在发送测试通知...'), duration: Duration(seconds: 1)),
              );

              // 初始化通知服务
              await NotificationService.initialize();

              // 发送测试通知
              bool success = await NotificationService.showInstantNotification(
                title: '节气提醒',
                body: '这是一个测试通知 🌿',
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('测试通知已发送 ✅')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('发送测试通知失败，请检查通知权限')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: '选择年份',
            onPressed: _showYearPicker,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: '设置节气提醒',
            onPressed: _scheduleAllJieQiNotifications,
          ),

        ],

      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentJieQiTab(),
          _buildAllJieQiTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentJieQiTab() {
    return FutureBuilder<JieQi?>(
      future: _currentJieQiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载错误: ${snapshot.error}'));
        }

        final JieQi? currentJieQi = snapshot.data;
        if (currentJieQi == null) {
          return const Center(child: Text('暂无节气数据'));
        }

        return Center(
          child: JieQiCard(jieQi: currentJieQi),
        );
      },
    );
  }

  Widget _buildAllJieQiTab() {
    return FutureBuilder<List<JieQi>>(
      future: _jieQiListFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('加载错误: ${snapshot.error}'));
        }

        final List<JieQi> jieQiList = snapshot.data ?? [];
        if (jieQiList.isEmpty) {
          return const Center(child: Text('无节气数据'));
        }

        // 计算当前日期在哪两个节气之间
        DateTime now = DateTime.now();
        int currentIndex = -1;

        if (_selectedYear == DateTime.now().year) {
          for (int i = 0; i < jieQiList.length - 1; i++) {
            if (now.isAfter(jieQiList[i].dateTime) &&
                now.isBefore(jieQiList[i + 1].dateTime)) {
              currentIndex = i;
              break;
            }
          }

          // 如果是今年最后一个节气之后
          if (currentIndex == -1 && now.isAfter(jieQiList.last.dateTime)) {
            currentIndex = jieQiList.length - 1;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: jieQiList.length,
          itemBuilder: (context, index) {
            final jieqi = jieQiList[index];
            bool isCurrent = index == currentIndex;
            bool isPast = _selectedYear == DateTime.now().year &&
                now.isAfter(jieqi.dateTime);

            return JieQiListItem(
              jieqi: jieqi,
              isCurrent: isCurrent,
              isPast: isPast,
            );
          },
        );
      },
    );
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择年份'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                Navigator.pop(context);
                setState(() {
                  _selectedYear = dateTime.year;
                  _loadJieQiData();
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _scheduleAllJieQiNotifications() async {
    // 显示加载指示器
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在设置节气提醒...'), duration: Duration(seconds: 1)),
    );

    // 首先尝试初始化通知服务
    bool initSuccess = await NotificationService.initialize();
    if (!initSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('初始化通知服务失败，请检查应用权限')),
        );
      }
      return;
    }

    // 检查通知权限状态
    bool permissionStatus = await NotificationService.checkPermissionStatus();
    if (!permissionStatus) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法检查通知权限状态')),
        );
      }
      // 继续尝试，因为权限可能已经在main.dart中请求过
    }

    try {
      final snapshot = await _jieQiListFuture;
      int scheduledCount = 0;

      // 清除旧的通知
      await NotificationService.cancelAll();

      // 设置新的通知
      for (int i = 0; i < snapshot.length; i++) {
        final jieqi = snapshot[i];
        final DateTime now = DateTime.now();

        if (jieqi.dateTime.isAfter(now)) {
          bool success = await NotificationService.scheduleJieQiNotification(
            id: i,
            title: '节气提醒',
            body: '${jieqi.name} 将于 ${_formatDate(jieqi.dateTime)} 到来 🌿',
            scheduledTime: jieqi.dateTime,
            reminderBefore: const Duration(days: 1),
          );

          if (success) {
            scheduledCount++;
          }
        }
      }

      // 检查待处理的通知
      await NotificationService.checkPendingNotifications();

      if (mounted) {
        if (scheduledCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已成功设置 $scheduledCount 个节气提醒 ✅')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有找到需要提醒的未来节气')),
          );
        }
      }
    } catch (e) {
      debugPrint('设置节气提醒异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置节气提醒失败: $e')),
        );
      }
    }
  }


  String _formatDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }


}
