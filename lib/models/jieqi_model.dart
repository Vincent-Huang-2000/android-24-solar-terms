// lib/models/jieqi_model.dart
class JieQi {
  final String name;      // 节气名称
  final DateTime dateTime; // 节气日期时间
  
  JieQi({required this.name, required this.dateTime});
  
  // 获取格式化的日期字符串
  String getFormattedDate() {
    return "${dateTime.year}年${dateTime.month}月${dateTime.day}日 "
           "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
  
  // 简短日期格式
  String getShortDate() {
    return "${dateTime.month}月${dateTime.day}日";
  }
  
  // 获取季节
  String getSeason() {
    final List<String> springJieqi = ['立春', '雨水', '惊蛰', '春分', '清明', '谷雨'];
    final List<String> summerJieqi = ['立夏', '小满', '芒种', '夏至', '小暑', '大暑'];
    final List<String> autumnJieqi = ['立秋', '处暑', '白露', '秋分', '寒露', '霜降'];
    final List<String> winterJieqi = ['立冬', '小雪', '大雪', '冬至', '小寒', '大寒'];
    
    if (springJieqi.contains(name)) return '春';
    if (summerJieqi.contains(name)) return '夏';
    if (autumnJieqi.contains(name)) return '秋';
    if (winterJieqi.contains(name)) return '冬';
    
    return '';
  }
}
