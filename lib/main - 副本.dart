// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/jieqi_calculator.dart';
import 'models/jieqi_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showYearPicker,
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
          child: _buildCurrentJieQiCard(currentJieQi),
        );
      },
    );
  }
  
  Widget _buildCurrentJieQiCard(JieQi jieQi) {
    // 为不同季节选择不同背景色和图标
    Color bgColor = Colors.green;
    IconData seasonIcon;
    
    switch (jieQi.getSeason()) {
      case '春':
        bgColor = Colors.green;
        seasonIcon = Icons.local_florist;
        break;
      case '夏':
        bgColor = Colors.redAccent;
        seasonIcon = Icons.wb_sunny;
        break;
      case '秋':
        bgColor = Colors.orange;
        seasonIcon = Icons.eco;
        break;
      case '冬':
        bgColor = Colors.blue;
        seasonIcon = Icons.ac_unit;
        break;
      default:
        bgColor = Colors.teal;
        seasonIcon = Icons.calendar_today;
    }
    
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor.withOpacity(0.7), bgColor.withOpacity(0.2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '当前节气',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              seasonIcon,
              color: bgColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              jieQi.name,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              jieQi.getFormattedDate(),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            _buildJieQiDescription(jieQi),
          ],
        ),
      ),
    );
  }
  
  Widget _buildJieQiDescription(JieQi jieQi) {
    // 节气描述信息
    final Map<String, String> jieQiDescriptions = {
      '立春': '立春是二十四节气中的第一个节气，表示着春季的开始，万物开始复苏。',
      '雨水': '雨水节气标志着降雨开始，雨量渐增，气温回升，万物开始萌动。',
      '惊蛰': '惊蛰是指春雷乍动，惊醒蛰伏于地下冬眠的昆虫和小动物。',
      '春分': '春分表示昼夜平分，白天和黑夜一样长，之后昼长夜短。',
      '清明': '清明节气是传统的扫墓祭祖、踏青郊游的好时节，此时气候温和，草木萌发。',
      '谷雨': '谷雨表示春季最后一个节气，雨水增多，有利于谷类农作物生长。',
      '立夏': '立夏标志着夏季的开始，气温显著升高，万物繁茂。',
      '小满': '小满表示春作物籽粒开始灌浆饱满，但还未完全成熟。',
      '芒种': '芒种是指麦类等有芒作物成熟收获的节气，也是水稻等夏播作物的种植时期。',
      '夏至': '夏至是一年中白天最长的一天，太阳直射北回归线，正午时分日影最短。',
      '小暑': '小暑意味着炎热的天气开始，但还未达到最热。',
      '大暑': '大暑是一年中最热的节气，正值"三伏天"里的"中伏"前后。',
      '立秋': '立秋表示秋季的开始，意味着炎热的夏季即将过去，天气逐渐转凉。',
      '处暑': '处暑表示炎热的天气结束，暑气渐消。',
      '白露': '白露表示天气转凉，早晨草木上有白色露珠。',
      '秋分': '秋分与春分相似，表示昼夜平分，之后夜长昼短。',
      '寒露': '寒露表示气温下降，露水更加寒冷，将要凝结成霜。',
      '霜降': '霜降表示天气更冷，开始有霜冻出现，是秋季的最后一个节气。',
      '立冬': '立冬表示冬季的开始，万物开始收藏，天气变得寒冷干燥。',
      '小雪': '小雪表示气温显著下降，开始降雪，但雪量较小。',
      '大雪': '大雪表示降雪量增多，天气更加寒冷。',
      '冬至': '冬至是一年中白天最短的一天，北半球地区阳光最少。',
      '小寒': '小寒表示寒冷开始加剧，但尚未达到最冷。',
      '大寒': '大寒是一年中最冷的节气，标志着隆冬时节。',
    };
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        jieQiDescriptions[jieQi.name] ?? '暂无描述',
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
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
            
            return _buildJieQiListItem(jieqi, isCurrent, isPast);
          },
        );
      },
    );
  }
  
  Widget _buildJieQiListItem(JieQi jieqi, bool isCurrent, bool isPast) {
    Color seasonColor;
    IconData seasonIcon;
    
    switch (jieqi.getSeason()) {
      case '春':
        seasonColor = Colors.green;
        seasonIcon = Icons.local_florist;
        break;
      case '夏':
        seasonColor = Colors.redAccent;
        seasonIcon = Icons.wb_sunny;
        break;
      case '秋':
        seasonColor = Colors.orange;
        seasonIcon = Icons.eco;
        break;
      case '冬':
        seasonColor = Colors.blue;
        seasonIcon = Icons.ac_unit;
        break;
      default:
        seasonColor = Colors.teal;
        seasonIcon = Icons.event;
    }
    
    return Card(
      elevation: isCurrent ? 8 : 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent 
            ? BorderSide(color: seasonColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : seasonColor,
          foregroundColor: Colors.white,
          child: Icon(seasonIcon),
        ),
        title: Text(
          jieqi.name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 18,
          ),
        ),
        subtitle: Text(jieqi.getFormattedDate()),
        trailing: isPast 
            ? const Icon(Icons.check_circle, color: Colors.grey) 
            : (isCurrent 
                ? Icon(Icons.star, color: seasonColor) 
                : null),
      ),
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
}
