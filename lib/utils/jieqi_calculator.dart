// lib/utils/jieqi_calculator.dart
import 'package:sweph/sweph.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import '../models/jieqi_model.dart';

// Flutter资产加载器 - 直接从Flutter资产中加载文件
class _FlutterAssetLoader implements AssetLoader {
  @override
  Future<Uint8List> load(String assetPath) async {
    try {
      // 直接从Flutter资产包中加载
      ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print('加载资产失败: $assetPath - $e');
      rethrow;
    }
  }
}

class JieQiCalculator {
  static bool _initialized = false;

  // 初始化sweph库
  static Future<void> initSweph() async {
    if (_initialized) return;

    try {
      // 获取可写目录
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String epheFilesPath = '${appDocDir.path}/ephe_files';

      // 确保目录存在
      Directory(epheFilesPath).createSync(recursive: true);

      print('初始化Sweph，星历表路径: $epheFilesPath');

      await Sweph.init(
        epheAssets: [
          'assets/ephe/seas_18.se1',
          'assets/ephe/semo_18.se1',
        ],
        epheFilesPath: epheFilesPath,
        assetLoader: _FlutterAssetLoader(),  // 使用Flutter资产加载器
      );

      _initialized = true;
      print('Sweph初始化成功');
    } catch (e) {
      print('Sweph初始化失败: $e');
      rethrow;
    }
  }

  // 获取指定年份的所有二十四节气
  static Future<List<JieQi>> getJieQiList(int year) async {
    // 确保初始化
    await initSweph();

    List<JieQi> result = [];

    // 二十四节气名称列表
    final List<String> jieqiNames = [
      '立春', '雨水', '惊蛰', '春分', '清明', '谷雨',
      '立夏', '小满', '芒种', '夏至', '小暑', '大暑',
      '立秋', '处暑', '白露', '秋分', '寒露', '霜降',
      '立冬', '小雪', '大雪', '冬至', '小寒', '大寒'
    ];

    try {
      // 节气对应的黄经度数（每15度一个节气）
      for (int i = 0; i < 24; i++) {
        // 黄经是从0度（春分）开始，每次增加15度
        double solarLongitude = i * 15.0;

        // 计算节气的时间
        DateTime jieqiTime = await calculateJieqiTime(year, solarLongitude);

        // 节气索引：从春分(0)开始
        int nameIndex = (i + 3) % 24;  // 春分对应索引3，所以加3再取模

        result.add(JieQi(name: jieqiNames[nameIndex], dateTime: jieqiTime));
      }

      // 按日期排序
      result.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    } catch (e) {
      print('计算节气出错: $e');
      rethrow;
    }

    return result;
  }

  // 计算太阳到达特定黄经时的时间
  static Future<DateTime> calculateJieqiTime(int year, double targetLongitude) async {
    // 对目标黄经进行标准化，确保在0-360度范围内
    targetLongitude = targetLongitude % 360;

    // 预估时间范围：取前后一个月，确保包含目标节气
    double startJd = Sweph.swe_julday(year - 1, 12, 1, 0, CalendarType.SE_GREG_CAL);
    double endJd = Sweph.swe_julday(year + 1, 1, 31, 0, CalendarType.SE_GREG_CAL);

    // 使用二分法查找节气时间
    double jd = await _findSolarTermJd(startJd, endJd, targetLongitude);

    // 转换为DateTime并返回
    return _julianDayToDateTime(jd);
  }

  // 使用二分法查找太阳到达特定黄经的时刻
  static Future<double> _findSolarTermJd(double startJd, double endJd, double targetLongitude) async {
    // 设置精度：1分钟
    const double precision = 1.0 / 1440.0;
    double midJd;

    while ((endJd - startJd) > precision) {
      midJd = (startJd + endJd) / 2.0;

      double currentLongitude = _getSunLongitude(midJd);

      // 计算两个角度之间的最短距离
      double diff = _angleDifference(currentLongitude, targetLongitude);

      if (diff < 0) {
        // 太阳还没到达目标黄经
        startJd = midJd;
      } else {
        // 太阳已经过了目标黄经
        endJd = midJd;
      }
    }

    // 返回找到的时刻
    return (startJd + endJd) / 2.0;
  }

  // 计算两个角度之间的最短距离（考虑跨越360度的情况）
  static double _angleDifference(double angle1, double angle2) {
    double diff = (angle1 - angle2) % 360;
    if (diff > 180) diff -= 360;
    return diff;
  }

  // 计算指定儒略日的太阳黄经
  static double _getSunLongitude(double jd) {
    try {
      // // 计算太阳的位置
      // var result = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN,
      //     SwephFlag.SEFLG_SWIEPH);
      // // 返回黄经（角度）
      // return result.longitude;

      var result = Sweph.swe_calc_ut(
          jd,
          HeavenlyBody.SE_SUN,
          SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SPEED // 不要加 NONUT
      );
      double sunLon = result.longitude % 360;
      return sunLon;

    } catch (e) {
      print('计算太阳黄经出错: $e');
      return 0;
    }
  }

  // 将儒略日转换为DateTime
  static DateTime _julianDayToDateTime(double jd) {
    try {
      // 这步拿到的 dtUtc 是在 UTC 时区下的 DateTime
      DateTime dtUtc = Sweph.swe_jdut1_to_utc(jd, CalendarType.SE_GREG_CAL);

      // 如果想**始终**以北京时间（UTC+8）显示，就手动加 8 小时
      // （中国大陆地区没有夏令时，所以固定 +8 就够了）
      return dtUtc.add(const Duration(hours: 8));

    } catch (e) {
      print('儒略日转换出错: $e');

      // 如果上面出异常，就用你原先的备用算法
      return _manualJdToDateTime(jd).add(const Duration(hours: 8));
    }
  }

  // 手动计算儒略日到DateTime的转换（备用方法）
  static DateTime _manualJdToDateTime(double jd) {
    // 将儒略日调整到格里高利历
    jd += 0.5;
    int Z = jd.floor();
    double F = jd - Z;

    int alpha = ((Z - 1867216.25) / 36524.25).floor();
    int A = Z + 1 + alpha - (alpha / 4).floor();

    int B = A + 1524;
    int C = ((B - 122.1) / 365.25).floor();
    int D = (365.25 * C).floor();
    int E = ((B - D) / 30.6001).floor();

    double day = B - D - (30.6001 * E).floor() + F;
    int month = (E < 14) ? E - 1 : E - 13;
    int year = (month > 2) ? C - 4716 : C - 4715;

    int hour = ((day - day.floor()) * 24).floor();
    int minute = (((day - day.floor()) * 24 - hour) * 60).floor();
    int second = (((day - day.floor()) * 24 - hour - minute / 60) * 3600).round();

    // 处理进位
    if (second == 60) {
      second = 0;
      minute++;
    }
    if (minute == 60) {
      minute = 0;
      hour++;
    }
    if (hour == 24) {
      hour = 0;
      day = day.floor() + 1;
    }

    return DateTime.utc(year, month, day.floor(), hour, minute, second).toLocal();
  }

  // 获取当前节气
  static Future<JieQi?> getCurrentJieQi() async {
    int currentYear = DateTime.now().year;
    List<JieQi> jieqiList = await getJieQiList(currentYear);

    DateTime now = DateTime.now();

    // 检查当前是否在某个节气之后、下一个节气之前
    for (int i = 0; i < jieqiList.length - 1; i++) {
      if (now.isAfter(jieqiList[i].dateTime) &&
          now.isBefore(jieqiList[i + 1].dateTime)) {
        return jieqiList[i];
      }
    }

    // 检查是否是当前年最后一个节气之后
    if (now.isAfter(jieqiList.last.dateTime)) {
      // 获取下一年的第一个节气
      List<JieQi> nextYearJieqi = await getJieQiList(currentYear + 1);

      // 如果当前时间在今年最后一个节气之后但在明年第一个节气之前
      if (now.isBefore(nextYearJieqi.first.dateTime)) {
        return jieqiList.last;
      }
    }

    // 检查是否是当前年第一个节气之前
    if (now.isBefore(jieqiList.first.dateTime)) {
      // 获取上一年的节气
      List<JieQi> prevYearJieqi = await getJieQiList(currentYear - 1);

      // 如果当前时间在去年最后一个节气之后但在今年第一个节气之前
      if (prevYearJieqi.isNotEmpty && now.isAfter(prevYearJieqi.last.dateTime)) {
        return prevYearJieqi.last;
      }
    }

    return null;
  }
}
