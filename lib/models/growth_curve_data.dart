// lib/growth_curve_data.dart

import 'package:fl_chart/fl_chart.dart';

/// 男孩體重成長曲線數據 (0-36個月) - WHO 高密度最終修正版
/// 數據來源：世界衛生組織 (WHO)
class BoyWeightData {
  BoyWeightData._();

  // 第 3 百分位
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 2.5), FlSpot(1, 3.4),
    FlSpot(2, 4.4), FlSpot(3, 5.1),
    FlSpot(4, 5.6),  FlSpot(5, 6.1),
    FlSpot(6, 6.4), FlSpot(7, 6.7), FlSpot(8, 7.0), FlSpot(9, 7.2),
    FlSpot(10, 7.5), FlSpot(11, 7.7), FlSpot(12, 7.8), FlSpot(13, 8.0),
    FlSpot(14, 8.2), FlSpot(15, 8.4), FlSpot(16, 8.5), FlSpot(17, 8.7),
    FlSpot(18, 8.9), FlSpot(19, 9.0), FlSpot(20, 9.2), FlSpot(21, 9.4),
    FlSpot(22, 9.5), FlSpot(23, 9.6), FlSpot(24, 9.7), FlSpot(25, 9.9),
    FlSpot(26, 10.0), FlSpot(27, 10.2), FlSpot(28, 10.3), FlSpot(29, 10.4),
    FlSpot(30, 10.5), FlSpot(31, 10.7), FlSpot(32, 10.8), FlSpot(33, 10.9),
    FlSpot(34, 11.1), FlSpot(35, 11.2), FlSpot(36, 11.3),
  ];

  // 第 15 百分位
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 2.9), FlSpot(1, 3.9),
    FlSpot(2, 4.9),  FlSpot(3, 5.8),
    FlSpot(4, 6.4),  FlSpot(5, 6.9),
    FlSpot(6, 7.3), FlSpot(7, 7.6), FlSpot(8, 8.0), FlSpot(9, 8.3),
    FlSpot(10, 8.5), FlSpot(11, 8.7), FlSpot(12, 8.9), FlSpot(13, 9.1),
    FlSpot(14, 9.3), FlSpot(15, 9.6), FlSpot(16, 9.8), FlSpot(17, 10.0),
    FlSpot(18, 10.2), FlSpot(19, 10.4), FlSpot(20, 10.5), FlSpot(21, 10.7),
    FlSpot(22, 10.9), FlSpot(23, 11.1), FlSpot(24, 11.2), FlSpot(25, 11.4),
    FlSpot(26, 11.6), FlSpot(27, 11.7), FlSpot(28, 11.9), FlSpot(29, 12.0),
    FlSpot(30, 12.2), FlSpot(31, 12.3), FlSpot(32, 12.5), FlSpot(33, 12.6),
    FlSpot(34, 12.8), FlSpot(35, 12.9), FlSpot(36, 13.0),
  ];

  // 第 25 百分位
  static const List<FlSpot> percentile25 = [
    FlSpot(0, 3.0), FlSpot(1, 4.1),
    FlSpot(2, 5.1), FlSpot(3, 6.0),
    FlSpot(4, 6.6), FlSpot(5, 7.1),
    FlSpot(6, 7.5), FlSpot(7, 7.9), FlSpot(8, 8.2), FlSpot(9, 8.5),
    FlSpot(10, 8.8), FlSpot(11, 9.0), FlSpot(12, 9.2), FlSpot(13, 9.4),
    FlSpot(14, 9.7), FlSpot(15, 9.9), FlSpot(16, 10.1), FlSpot(17, 10.3),
    FlSpot(18, 10.5), FlSpot(19, 10.7), FlSpot(20, 10.9), FlSpot(21, 11.0),
    FlSpot(22, 11.2), FlSpot(23, 11.4), FlSpot(24, 11.5), FlSpot(25, 11.7),
    FlSpot(26, 11.9), FlSpot(27, 12.1), FlSpot(28, 12.2), FlSpot(29, 12.4),
    FlSpot(30, 12.5), FlSpot(31, 12.7), FlSpot(32, 12.8), FlSpot(33, 13.0),
    FlSpot(34, 13.2), FlSpot(35, 13.3), FlSpot(36, 13.4),
  ];

  // 第 50 百分位
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 3.3), FlSpot(1, 4.5),
    FlSpot(2, 5.6), FlSpot(3, 6.5),
    FlSpot(4, 7.2), FlSpot(5, 7.8),
    FlSpot(6, 8.2), FlSpot(7, 8.5), FlSpot(8, 8.8), FlSpot(9, 9.1),
    FlSpot(10, 9.4), FlSpot(11, 9.7), FlSpot(12, 9.9), FlSpot(13, 10.1),
    FlSpot(14, 10.3), FlSpot(15, 10.6), FlSpot(16, 10.8), FlSpot(17, 11.0),
    FlSpot(18, 11.2), FlSpot(19, 11.4), FlSpot(20, 11.6), FlSpot(21, 11.8),
    FlSpot(22, 12.0), FlSpot(23, 12.2), FlSpot(24, 12.3), FlSpot(25, 12.5),
    FlSpot(26, 12.7), FlSpot(27, 12.9), FlSpot(28, 13.1), FlSpot(29, 13.2),
    FlSpot(30, 13.4), FlSpot(31, 13.6), FlSpot(32, 13.7), FlSpot(33, 13.8),
    FlSpot(34, 14.0), FlSpot(35, 14.2), FlSpot(36, 14.3),
  ];

  // 第 75 百分位
  static const List<FlSpot> percentile75 = [
    FlSpot(0, 3.7), FlSpot(1, 4.9),
    FlSpot(2, 6.0), FlSpot(3, 7.1),
    FlSpot(4, 7.8), FlSpot(5, 8.4),
    FlSpot(6, 8.8), FlSpot(7, 9.2), FlSpot(8, 9.5), FlSpot(9, 9.8),
    FlSpot(10, 10.1), FlSpot(11, 10.4), FlSpot(12, 10.7), FlSpot(13, 10.9),
    FlSpot(14, 11.2), FlSpot(15, 11.4), FlSpot(16, 11.7), FlSpot(17, 11.9),
    FlSpot(18, 12.1), FlSpot(19, 12.3), FlSpot(20, 12.5), FlSpot(21, 12.7),
    FlSpot(22, 12.9), FlSpot(23, 13.1), FlSpot(24, 13.3), FlSpot(25, 13.5),
    FlSpot(26, 13.7), FlSpot(27, 13.9), FlSpot(28, 14.1), FlSpot(29, 14.3),
    FlSpot(30, 14.5), FlSpot(31, 14.7), FlSpot(32, 14.8), FlSpot(33, 15.0),
    FlSpot(34, 15.2), FlSpot(35, 15.4), FlSpot(36, 15.5),
  ];

  // 第 85 百分位
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 3.9), FlSpot(1, 5.1),
    FlSpot(2, 6.3), FlSpot(3, 7.4),
    FlSpot(4, 8.1), FlSpot(5, 8.7),
    FlSpot(6, 9.2), FlSpot(7, 9.5), FlSpot(8, 9.9), FlSpot(9, 10.2),
    FlSpot(10, 10.5), FlSpot(11, 10.8), FlSpot(12, 11.0), FlSpot(13, 11.3),
    FlSpot(14, 11.5), FlSpot(15, 11.8), FlSpot(16, 12.0), FlSpot(17, 12.3),
    FlSpot(18, 12.5), FlSpot(19, 12.8), FlSpot(20, 13.0), FlSpot(21, 13.2),
    FlSpot(22, 13.5), FlSpot(23, 13.7), FlSpot(24, 13.8), FlSpot(25, 14.1),
    FlSpot(26, 14.3), FlSpot(27, 14.5), FlSpot(28, 14.7), FlSpot(29, 14.9),
    FlSpot(30, 15.1), FlSpot(31, 15.3), FlSpot(32, 15.4), FlSpot(33, 15.6),
    FlSpot(34, 15.8), FlSpot(35, 16.0), FlSpot(36, 16.1),
  ];

  // 第 97 百分位
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 4.3), FlSpot(1, 5.5),
    FlSpot(2, 6.8), FlSpot(3, 7.9),
    FlSpot(4, 8.6), FlSpot(5, 9.2),
    FlSpot(6, 9.7), FlSpot(7, 10.1), FlSpot(8, 10.5), FlSpot(9, 10.9),
    FlSpot(10, 11.2), FlSpot(11, 11.5), FlSpot(12, 11.8), FlSpot(13, 12.1),
    FlSpot(14, 12.4), FlSpot(15, 12.7), FlSpot(16, 13.0), FlSpot(17, 13.3),
    FlSpot(18, 13.5), FlSpot(19, 13.8), FlSpot(20, 14.0), FlSpot(21, 14.3),
    FlSpot(22, 14.5), FlSpot(23, 14.8), FlSpot(24, 15.0), FlSpot(25, 15.3),
    FlSpot(26, 15.5), FlSpot(27, 15.8), FlSpot(28, 16.0), FlSpot(29, 16.2),
    FlSpot(30, 16.5), FlSpot(31, 16.7), FlSpot(32, 16.9), FlSpot(33, 17.1),
    FlSpot(34, 17.4), FlSpot(35, 17.6), FlSpot(36, 17.8),
  ];

// ✅ 修改 allPercentiles 列表，只保留 5 條線
  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}

/// 女孩體重成長曲線數據 (0-36個月) - WHO 高密度修正版
/// 數據來源：世界衛生組織 (WHO)
class GirlWeightData {
  GirlWeightData._();

  // 第 3 百分位
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 2.4), FlSpot(1, 3.2),
    FlSpot(2, 4.0), FlSpot(3, 4.6),
    FlSpot(4, 5.1), FlSpot(5, 5.5),
    FlSpot(6, 5.8), FlSpot(7, 6.1), FlSpot(8, 6.3), FlSpot(9, 6.6),
    FlSpot(10, 6.8), FlSpot(11, 7.0), FlSpot(12, 7.1), FlSpot(13, 7.3),
    FlSpot(14, 7.5), FlSpot(15, 7.7), FlSpot(16, 7.9), FlSpot(17, 8.1),
    FlSpot(18, 8.2), FlSpot(19, 8.4), FlSpot(20, 8.6), FlSpot(21, 8.7),
    FlSpot(22, 8.9), FlSpot(23, 9.0), FlSpot(24, 9.2), FlSpot(25, 9.3),
    FlSpot(26, 9.5), FlSpot(27, 9.6), FlSpot(28, 9.8), FlSpot(29, 9.9),
    FlSpot(30, 10.1), FlSpot(31, 10.2), FlSpot(32, 10.4), FlSpot(33, 10.5),
    FlSpot(34, 10.7), FlSpot(35, 10.8), FlSpot(36, 11.0),
  ];

  // 第 15 百分位
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 2.8), FlSpot(1, 3.6),
    FlSpot(2, 4.5), FlSpot(3, 5.2),
    FlSpot(4, 5.8), FlSpot(5, 6.2),
    FlSpot(6, 6.6), FlSpot(7, 6.9), FlSpot(8, 7.2), FlSpot(9, 7.4),
    FlSpot(10, 7.6), FlSpot(11, 7.8), FlSpot(12, 8.0), FlSpot(13, 8.2),
    FlSpot(14, 8.4), FlSpot(15, 8.6), FlSpot(16, 8.8), FlSpot(17, 9.0),
    FlSpot(18, 9.1), FlSpot(19, 9.3), FlSpot(20, 9.5), FlSpot(21, 9.6),
    FlSpot(22, 9.8), FlSpot(23, 10.0), FlSpot(24, 10.2), FlSpot(25, 10.3),
    FlSpot(26, 10.5), FlSpot(27, 10.7), FlSpot(28, 10.8), FlSpot(29, 11.0),
    FlSpot(30, 11.2), FlSpot(31, 11.3), FlSpot(32, 11.5), FlSpot(33, 11.6),
    FlSpot(34, 11.8), FlSpot(35, 12.0), FlSpot(36, 12.1),
  ];

  // 第 25 百分位
  static const List<FlSpot> percentile25 = [
    FlSpot(0, 2.9), FlSpot(1, 3.8),
    FlSpot(2, 4.7), FlSpot(3, 5.4),
    FlSpot(4, 6.0), FlSpot(5, 6.4),
    FlSpot(6, 6.8), FlSpot(7, 7.2), FlSpot(8, 7.4), FlSpot(9, 7.7),
    FlSpot(10, 7.9), FlSpot(11, 8.1), FlSpot(12, 8.3), FlSpot(13, 8.5),
    FlSpot(14, 8.7), FlSpot(15, 8.9), FlSpot(16, 9.1), FlSpot(17, 9.3),
    FlSpot(18, 9.5), FlSpot(19, 9.7), FlSpot(20, 9.9), FlSpot(21, 10.0),
    FlSpot(22, 10.2), FlSpot(23, 10.4), FlSpot(24, 10.6), FlSpot(25, 10.8),
    FlSpot(26, 10.9), FlSpot(27, 11.1), FlSpot(28, 11.3), FlSpot(29, 11.5),
    FlSpot(30, 11.7), FlSpot(31, 11.8), FlSpot(32, 12.0), FlSpot(33, 12.2),
    FlSpot(34, 12.4), FlSpot(35, 12.6), FlSpot(36, 12.7),
  ];

  // 第 50 百分位
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 3.2),  FlSpot(1, 4.2),
    FlSpot(2, 5.1), FlSpot(3, 5.8),
    FlSpot(4, 6.4), FlSpot(5, 6.9),
    FlSpot(6, 7.3), FlSpot(7, 7.6), FlSpot(8, 7.9), FlSpot(9, 8.2),
    FlSpot(10, 8.5), FlSpot(11, 8.7), FlSpot(12, 8.9), FlSpot(13, 9.2),
    FlSpot(14, 9.4), FlSpot(15, 9.6), FlSpot(16, 9.8), FlSpot(17, 10.0),
    FlSpot(18, 10.2), FlSpot(19, 10.4), FlSpot(20, 10.6), FlSpot(21, 10.9),
    FlSpot(22, 11.1), FlSpot(23, 11.3), FlSpot(24, 11.5), FlSpot(25, 11.7),
    FlSpot(26, 11.9), FlSpot(27, 12.1), FlSpot(28, 12.3), FlSpot(29, 12.5),
    FlSpot(30, 12.7), FlSpot(31, 12.9), FlSpot(32, 13.1), FlSpot(33, 13.3),
    FlSpot(34, 13.5), FlSpot(35, 13.7), FlSpot(36, 13.9),
  ];

  // 第 75 百分位
  static const List<FlSpot> percentile75 = [
    FlSpot(0, 3.6),  FlSpot(1, 4.6),
    FlSpot(2, 5.6),  FlSpot(3, 6.4),
    FlSpot(4, 7.0), FlSpot(5, 7.5),
    FlSpot(6, 8.0), FlSpot(7, 8.3), FlSpot(8, 8.6), FlSpot(9, 8.9),
    FlSpot(10, 9.2), FlSpot(11, 9.5), FlSpot(12, 9.8), FlSpot(13, 10.1),
    FlSpot(14, 10.3), FlSpot(15, 10.5), FlSpot(16, 10.7), FlSpot(17, 11.0),
    FlSpot(18, 11.2), FlSpot(19, 11.4), FlSpot(20, 11.6), FlSpot(21, 11.9),
    FlSpot(22, 12.1), FlSpot(23, 12.4), FlSpot(24, 12.6), FlSpot(25, 12.8),
    FlSpot(26, 13.0), FlSpot(27, 13.2), FlSpot(28, 13.4), FlSpot(29, 13.6),
    FlSpot(30, 13.8), FlSpot(31, 14.0), FlSpot(32, 14.3), FlSpot(33, 14.5),
    FlSpot(34, 14.7), FlSpot(35, 14.9), FlSpot(36, 15.1),
  ];

  // 第 85 百分位
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 3.7), FlSpot(1, 4.8),
    FlSpot(2, 5.9), FlSpot(3, 6.7),
    FlSpot(4, 7.4), FlSpot(5, 7.9),
    FlSpot(6, 8.4), FlSpot(7, 8.7), FlSpot(8, 9.0), FlSpot(9, 9.4),
    FlSpot(10, 9.7), FlSpot(11, 10.0), FlSpot(12, 10.2), FlSpot(13, 10.5),
    FlSpot(14, 10.8), FlSpot(15, 11.0), FlSpot(16, 11.3), FlSpot(17, 11.5),
    FlSpot(18, 11.7), FlSpot(19, 12.0), FlSpot(20, 12.2), FlSpot(21, 12.5),
    FlSpot(22, 12.7), FlSpot(23, 13.0), FlSpot(24, 13.2), FlSpot(25, 13.4),
    FlSpot(26, 13.6), FlSpot(27, 13.8), FlSpot(28, 14.1), FlSpot(29, 14.3),
    FlSpot(30, 14.5), FlSpot(31, 14.7), FlSpot(32, 14.9), FlSpot(33, 15.2),
    FlSpot(34, 15.4), FlSpot(35, 15.6), FlSpot(36, 15.9),
  ];

  // 第 97 百分位
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 4.2), FlSpot(1, 5.4),
    FlSpot(2, 6.5), FlSpot(3, 7.5),
    FlSpot(4, 8.2), FlSpot(5, 8.8),
    FlSpot(6, 9.3), FlSpot(7, 9.7), FlSpot(8, 10.1), FlSpot(9, 10.5),
    FlSpot(10, 10.8), FlSpot(11, 11.1), FlSpot(12, 11.4), FlSpot(13, 11.7),
    FlSpot(14, 12.0), FlSpot(15, 12.3), FlSpot(16, 12.6), FlSpot(17, 12.9),
    FlSpot(18, 13.2), FlSpot(19, 13.5), FlSpot(20, 13.8), FlSpot(21, 14.0),
    FlSpot(22, 14.3), FlSpot(23, 14.6), FlSpot(24, 14.8), FlSpot(25, 15.1),
    FlSpot(26, 15.3), FlSpot(27, 15.6), FlSpot(28, 15.8), FlSpot(29, 16.1),
    FlSpot(30, 16.3), FlSpot(31, 16.6), FlSpot(32, 16.8), FlSpot(33, 17.0),
    FlSpot(34, 17.3), FlSpot(35, 17.5), FlSpot(36, 17.8),
  ];

// ✅ 修改 allPercentiles 列表，只保留 5 條線
  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}

/// 男孩身高成長曲線數據 (0-36個月) - WHO 高密度最終修正版
/// 數據來源：世界衛生組織 (WHO)
class BoyHeightData {
  BoyHeightData._();

  // 第 3 百分位
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 46.1), FlSpot(1, 50.3),
    FlSpot(2, 54.0), FlSpot(3, 57.1),
    FlSpot(4, 59.7), FlSpot(5, 61.9),
    FlSpot(6, 63.9), FlSpot(7, 65.7), FlSpot(8, 67.3), FlSpot(9, 68.8),
    FlSpot(10, 70.1), FlSpot(11, 71.4), FlSpot(12, 72.6), FlSpot(13, 73.8),
    FlSpot(14, 74.9), FlSpot(15, 76.1), FlSpot(16, 77.2), FlSpot(17, 78.2),
    FlSpot(18, 79.1), FlSpot(19, 80.0), FlSpot(20, 80.9), FlSpot(21, 81.7),
    FlSpot(22, 82.5), FlSpot(23, 83.3), FlSpot(24, 84.1), FlSpot(25, 84.8),
    FlSpot(26, 85.6), FlSpot(27, 86.3), FlSpot(28, 87.0), FlSpot(29, 87.7),
    FlSpot(30, 88.3), FlSpot(31, 89.0), FlSpot(32, 89.6), FlSpot(33, 90.2),
    FlSpot(34, 90.8), FlSpot(35, 91.4), FlSpot(36, 92.0),
  ];

  // 第 15 百分位
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 47.9), FlSpot(1, 52.2),
    FlSpot(2, 55.8), FlSpot(3, 59.1),
    FlSpot(4, 62.0), FlSpot(5, 64.4),
    FlSpot(6, 66.5), FlSpot(7, 68.3), FlSpot(8, 70.0), FlSpot(9, 71.5),
    FlSpot(10, 73.0), FlSpot(11, 74.3), FlSpot(12, 75.6), FlSpot(13, 76.8),
    FlSpot(14, 78.0), FlSpot(15, 79.2), FlSpot(16, 80.3), FlSpot(17, 81.4),
    FlSpot(18, 82.3), FlSpot(19, 83.3), FlSpot(20, 84.2), FlSpot(21, 85.0),
    FlSpot(22, 85.9), FlSpot(23, 86.7), FlSpot(24, 87.5), FlSpot(25, 88.3),
    FlSpot(26, 89.1), FlSpot(27, 89.8), FlSpot(28, 90.5), FlSpot(29, 91.2),
    FlSpot(30, 91.9), FlSpot(31, 92.5), FlSpot(32, 93.2), FlSpot(33, 93.9),
    FlSpot(34, 94.5), FlSpot(35, 95.1), FlSpot(36, 95.7),
  ];

  // 第 25 百分位
  static const List<FlSpot> percentile25 = [
    FlSpot(0, 48.6), FlSpot(1, 52.9),
    FlSpot(2, 56.6), FlSpot(3, 59.9),
    FlSpot(4, 62.8), FlSpot(5, 65.2),
    FlSpot(6, 67.4), FlSpot(7, 69.2), FlSpot(8, 70.9), FlSpot(9, 72.5),
    FlSpot(10, 74.0), FlSpot(11, 75.3), FlSpot(12, 76.6), FlSpot(13, 77.8),
    FlSpot(14, 79.0), FlSpot(15, 80.2), FlSpot(16, 81.3), FlSpot(17, 82.4),
    FlSpot(18, 83.4), FlSpot(19, 84.4), FlSpot(20, 85.3), FlSpot(21, 86.2),
    FlSpot(22, 87.0), FlSpot(23, 87.9), FlSpot(24, 88.8), FlSpot(25, 89.6),
    FlSpot(26, 90.3), FlSpot(27, 91.1), FlSpot(28, 91.8), FlSpot(29, 92.5),
    FlSpot(30, 93.2), FlSpot(31, 93.9), FlSpot(32, 94.5), FlSpot(33, 95.2),
    FlSpot(34, 95.8), FlSpot(35, 96.4), FlSpot(36, 97.0),
  ];

  // 第 50 百分位
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 49.9), FlSpot(1, 54.4),
    FlSpot(2, 58.0), FlSpot(3, 61.4),
    FlSpot(4, 64.3), FlSpot(5, 66.8),
    FlSpot(6, 69.0), FlSpot(7, 70.8), FlSpot(8, 72.5), FlSpot(9, 74.1),
    FlSpot(10, 75.6), FlSpot(11, 77.0), FlSpot(12, 78.3), FlSpot(13, 79.6),
    FlSpot(14, 80.8), FlSpot(15, 82.0), FlSpot(16, 83.2), FlSpot(17, 84.3),
    FlSpot(18, 85.1), FlSpot(19, 86.5), FlSpot(20, 87.3), FlSpot(21, 88.0),
    FlSpot(22, 88.9), FlSpot(23, 89.8), FlSpot(24, 90.7), FlSpot(25, 91.5),
    FlSpot(26, 92.3), FlSpot(27, 93.1), FlSpot(28, 93.8), FlSpot(29, 94.5),
    FlSpot(30, 95.2), FlSpot(31, 95.9), FlSpot(32, 96.5), FlSpot(33, 97.2),
    FlSpot(34, 97.8), FlSpot(35, 98.4), FlSpot(36, 99.1),
  ];

  // 第 75 百分位
  static const List<FlSpot> percentile75 = [
    FlSpot(0, 51.2), FlSpot(1, 55.8),
    FlSpot(2, 59.5), FlSpot(3, 62.9),
    FlSpot(4, 65.8), FlSpot(5, 68.3),
    FlSpot(6, 70.6), FlSpot(7, 72.4), FlSpot(8, 74.2), FlSpot(9, 75.8),
    FlSpot(10, 77.3), FlSpot(11, 78.8), FlSpot(12, 80.1), FlSpot(13, 81.4),
    FlSpot(14, 82.6), FlSpot(15, 83.8), FlSpot(16, 85.0), FlSpot(17, 86.0),
    FlSpot(18, 87.0), FlSpot(19, 88.0), FlSpot(20, 88.9), FlSpot(21, 89.9),
    FlSpot(22, 90.8), FlSpot(23, 91.7), FlSpot(24, 92.6), FlSpot(25, 93.5),
    FlSpot(26, 94.3), FlSpot(27, 95.1), FlSpot(28, 95.9), FlSpot(29, 96.7),
    FlSpot(30, 97.2), FlSpot(31, 98.2), FlSpot(32, 98.8), FlSpot(33, 99.3),
    FlSpot(34, 100.1), FlSpot(35, 100.7), FlSpot(36, 101.2),
  ];

  // 第 85 百分位
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 52.0), FlSpot(1, 56.6),
    FlSpot(2, 60.4), FlSpot(3, 63.8),
    FlSpot(4, 66.8), FlSpot(5, 69.2),
    FlSpot(6, 71.4), FlSpot(7, 73.3), FlSpot(8, 75.0), FlSpot(9, 76.7),
    FlSpot(10, 78.2), FlSpot(11, 79.7), FlSpot(12, 81.0), FlSpot(13, 82.3),
    FlSpot(14, 83.5), FlSpot(15, 84.8), FlSpot(16, 86.0), FlSpot(17, 87.0),
    FlSpot(18, 88.0), FlSpot(19, 89.1), FlSpot(20, 90.0), FlSpot(21, 90.9),
    FlSpot(22, 91.8), FlSpot(23, 92.7), FlSpot(24, 93.6), FlSpot(25, 94.4),
    FlSpot(26, 95.2), FlSpot(27, 96.1), FlSpot(28, 96.9), FlSpot(29, 97.6),
    FlSpot(30, 98.3), FlSpot(31, 99.0), FlSpot(32, 99.7), FlSpot(33, 100.3),
    FlSpot(34, 101.0), FlSpot(35, 101.6), FlSpot(36, 102.3),
  ];

  // 第 97 百分位
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 53.7), FlSpot(1, 58.4),
    FlSpot(2, 62.2),  FlSpot(3, 65.6),
    FlSpot(4, 68.6), FlSpot(5, 71.0),
    FlSpot(6, 73.3), FlSpot(7, 75.2), FlSpot(8, 76.9), FlSpot(9, 78.6),
    FlSpot(10, 80.1), FlSpot(11, 81.6), FlSpot(12, 82.9), FlSpot(13, 84.2),
    FlSpot(14, 85.5), FlSpot(15, 86.7), FlSpot(16, 88.0), FlSpot(17, 89.0),
    FlSpot(18, 90.0), FlSpot(19, 91.1), FlSpot(20, 92.1), FlSpot(21, 92.9),
    FlSpot(22, 93.9), FlSpot(23, 94.8), FlSpot(24, 95.6), FlSpot(25, 96.5),
    FlSpot(26, 97.4), FlSpot(27, 98.2), FlSpot(28, 99.0), FlSpot(29, 99.8),
    FlSpot(30, 100.3), FlSpot(31, 101.2), FlSpot(32, 101.8), FlSpot(33, 102.4),
    FlSpot(34, 103.1), FlSpot(35, 103.8), FlSpot(36, 104.5),
  ];

// ✅ 修改 allPercentiles 列表，只保留 5 條線
  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}

/// 女孩身高成長曲線數據 (0-36個月) - WHO 高密度最終修正版
/// 數據來源：世界衛生組織 (WHO)
class GirlHeightData {
  GirlHeightData._();

  // 第 3 百分位
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 45.6), FlSpot(1, 50.0),
    FlSpot(2, 53.2), FlSpot(3, 55.8),
    FlSpot(4, 58.0), FlSpot(5, 59.9),
    FlSpot(6, 61.5), FlSpot(7, 62.9), FlSpot(8, 64.3), FlSpot(9, 65.6),
    FlSpot(10, 66.8), FlSpot(11, 68.0), FlSpot(12, 69.2), FlSpot(13, 70.3),
    FlSpot(14, 71.3), FlSpot(15, 72.4), FlSpot(16, 73.3), FlSpot(17, 74.3),
    FlSpot(18, 75.2), FlSpot(19, 76.2), FlSpot(20, 77.0), FlSpot(21, 77.9),
    FlSpot(22, 78.7), FlSpot(23, 79.6), FlSpot(24, 80.3), FlSpot(25, 81.0),
    FlSpot(26, 81.7), FlSpot(27, 82.4), FlSpot(28, 83.1), FlSpot(29, 83.7),
    FlSpot(30, 84.4), FlSpot(31, 85.0), FlSpot(32, 85.6), FlSpot(33, 86.2),
    FlSpot(34, 86.8), FlSpot(35, 87.4), FlSpot(36, 87.9),
  ];

  // 第 15 百分位
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 47.2), FlSpot(1, 51.7),
    FlSpot(2, 55.0), FlSpot(3, 57.6),
    FlSpot(4, 59.8), FlSpot(5, 61.7),
    FlSpot(6, 63.4), FlSpot(7, 64.9), FlSpot(8, 66.3), FlSpot(9, 67.6),
    FlSpot(10, 68.9), FlSpot(11, 70.2), FlSpot(12, 71.3), FlSpot(13, 72.5),
    FlSpot(14, 73.6), FlSpot(15, 74.7), FlSpot(16, 75.7), FlSpot(17, 76.7),
    FlSpot(18, 77.7), FlSpot(19, 78.7), FlSpot(20, 79.6), FlSpot(21, 80.5),
    FlSpot(22, 81.4), FlSpot(23, 82.2), FlSpot(24, 83.1), FlSpot(25, 83.9),
    FlSpot(26, 84.7), FlSpot(27, 85.5), FlSpot(28, 86.2), FlSpot(29, 86.9),
    FlSpot(30, 87.6), FlSpot(31, 88.3), FlSpot(32, 88.9), FlSpot(33, 89.6),
    FlSpot(34, 90.2), FlSpot(35, 90.8), FlSpot(36, 91.1),
  ];

  // 第 25 百分位
  static const List<FlSpot> percentile25 = [
    FlSpot(0, 47.9), FlSpot(1, 52.4),
    FlSpot(2, 55.8), FlSpot(3, 58.7),
    FlSpot(4, 61.1), FlSpot(5, 63.2),
    FlSpot(6, 65.0), FlSpot(7, 66.5), FlSpot(8, 68.0), FlSpot(9, 69.4),
    FlSpot(10, 70.7), FlSpot(11, 72.0), FlSpot(12, 73.2), FlSpot(13, 74.4),
    FlSpot(14, 75.5), FlSpot(15, 76.6), FlSpot(16, 77.6), FlSpot(17, 78.7),
    FlSpot(18, 79.7), FlSpot(19, 80.6), FlSpot(20, 81.5), FlSpot(21, 82.5),
    FlSpot(22, 83.3), FlSpot(23, 84.2), FlSpot(24, 85.0), FlSpot(25, 85.8),
    FlSpot(26, 86.6), FlSpot(27, 87.4), FlSpot(28, 88.1), FlSpot(29, 88.8),
    FlSpot(30, 89.5), FlSpot(31, 90.2), FlSpot(32, 90.8), FlSpot(33, 91.5),
    FlSpot(34, 92.1), FlSpot(35, 92.8), FlSpot(36, 93.4),
  ];

  // 第 50 百分位
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 49.1), FlSpot(1, 53.7),
    FlSpot(2, 57.1), FlSpot(3, 59.8),
    FlSpot(4, 62.1), FlSpot(5, 64.0),
    FlSpot(6, 65.7), FlSpot(7, 67.3), FlSpot(8, 68.7), FlSpot(9, 70.1),
    FlSpot(10, 71.5), FlSpot(11, 72.8), FlSpot(12, 74.0), FlSpot(13, 75.2),
    FlSpot(14, 76.4), FlSpot(15, 77.5), FlSpot(16, 78.6), FlSpot(17, 79.7),
    FlSpot(18, 80.7), FlSpot(19, 81.7), FlSpot(20, 82.7), FlSpot(21, 83.7),
    FlSpot(22, 84.6), FlSpot(23, 85.5), FlSpot(24, 86.4), FlSpot(25, 87.2),
    FlSpot(26, 88.0), FlSpot(27, 88.8), FlSpot(28, 89.6), FlSpot(29, 90.3),
    FlSpot(30, 91.0), FlSpot(31, 91.7), FlSpot(32, 92.4), FlSpot(33, 93.1),
    FlSpot(34, 93.8), FlSpot(35, 94.4), FlSpot(36, 95.1),
  ];

  // 第 75 百分位
  static const List<FlSpot> percentile75 = [
    FlSpot(0, 50.4), FlSpot(1, 55.0),
    FlSpot(2, 58.5), FlSpot(3, 61.7),
    FlSpot(4, 64.3), FlSpot(5, 66.6),
    FlSpot(6, 68.7), FlSpot(7, 70.3), FlSpot(8, 71.8), FlSpot(9, 73.3),
    FlSpot(10, 74.7), FlSpot(11, 76.2), FlSpot(12, 77.5), FlSpot(13, 78.8),
    FlSpot(14, 80.0), FlSpot(15, 81.2), FlSpot(16, 82.3), FlSpot(17, 83.5),
    FlSpot(18, 84.5), FlSpot(19, 85.5), FlSpot(20, 86.5), FlSpot(21, 87.5),
    FlSpot(22, 88.4), FlSpot(23, 89.4), FlSpot(24, 90.2), FlSpot(25, 91.1),
    FlSpot(26, 91.9), FlSpot(27, 92.7), FlSpot(28, 93.5), FlSpot(29, 94.2),
    FlSpot(30, 95.0), FlSpot(31, 95.7), FlSpot(32, 96.4), FlSpot(33, 97.1),
    FlSpot(34, 97.8), FlSpot(35, 98.4), FlSpot(36, 99.1),
  ];

  // 第 85 百分位
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 51.1), FlSpot(1, 55.7),
    FlSpot(2, 59.2), FlSpot(3, 62.4),
    FlSpot(4, 65.1), FlSpot(5, 67.4),
    FlSpot(6, 69.5), FlSpot(7, 71.2), FlSpot(8, 72.8), FlSpot(9, 74.3),
    FlSpot(10, 75.8), FlSpot(11, 77.2), FlSpot(12, 78.6), FlSpot(13, 79.9),
    FlSpot(14, 81.1), FlSpot(15, 82.3), FlSpot(16, 83.5), FlSpot(17, 84.6),
    FlSpot(18, 85.7), FlSpot(19, 86.8), FlSpot(20, 87.8), FlSpot(21, 88.8),
    FlSpot(22, 89.8), FlSpot(23, 90.7), FlSpot(24, 91.6), FlSpot(25, 92.4),
    FlSpot(26, 93.3), FlSpot(27, 94.1), FlSpot(28, 94.9), FlSpot(29, 95.6),
    FlSpot(30, 96.4), FlSpot(31, 97.1), FlSpot(32, 97.8), FlSpot(33, 98.5),
    FlSpot(34, 99.2), FlSpot(35, 99.9), FlSpot(36, 100.5),
  ];

  // 第 97 百分位
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 52.7), FlSpot(1, 57.4),
    FlSpot(2, 60.9), FlSpot(3, 64.2),
    FlSpot(4, 67.0), FlSpot(5, 69.3),
    FlSpot(6, 71.4), FlSpot(7, 73.2), FlSpot(8, 74.9), FlSpot(9, 76.5),
    FlSpot(10, 78.0), FlSpot(11, 79.5), FlSpot(12, 80.9), FlSpot(13, 82.2),
    FlSpot(14, 83.5), FlSpot(15, 84.8), FlSpot(16, 86.0), FlSpot(17, 87.2),
    FlSpot(18, 88.3), FlSpot(19, 89.4), FlSpot(20, 90.5), FlSpot(21, 91.5),
    FlSpot(22, 92.5), FlSpot(23, 93.5), FlSpot(24, 94.4), FlSpot(25, 95.3),
    FlSpot(26, 96.1), FlSpot(27, 97.0), FlSpot(28, 97.8), FlSpot(29, 98.6),
    FlSpot(30, 99.3), FlSpot(31, 100.1), FlSpot(32, 100.8), FlSpot(33, 101.5),
    FlSpot(34, 102.2), FlSpot(35, 102.9), FlSpot(36, 103.5),
  ];

// ✅ 修改 allPercentiles 列表，只保留 5 條線
  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}

/// 男孩頭圍成長曲線數據 (0-36個月) - 高密度平滑版
/// 數據來源：世界衛生組織 (WHO)
class BoyHeadCircumferenceData {
  BoyHeadCircumferenceData._();

  // 第 3 百分位
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 32.1), FlSpot(1, 35.1),
    FlSpot(2, 36.9), FlSpot(3, 38.3),
    FlSpot(4, 39.3), FlSpot(5, 40.1),
    FlSpot(6, 40.8), FlSpot(7, 41.3), FlSpot(8, 41.7), FlSpot(9, 42.2),
    FlSpot(10, 42.6), FlSpot(11, 43.0), FlSpot(12, 43.3), FlSpot(15, 44.1),
    FlSpot(18, 44.8), FlSpot(21, 45.4), FlSpot(24, 45.9), FlSpot(27, 46.4),
    FlSpot(30, 46.8), FlSpot(33, 47.1), FlSpot(36, 47.4),
  ];

  // 第 15 百分位
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 33.1), FlSpot(1, 36.1),
    FlSpot(2, 37.9), FlSpot(3, 39.3),
    FlSpot(4, 40.3), FlSpot(5, 41.1),
    FlSpot(6, 41.8), FlSpot(7, 42.3), FlSpot(8, 42.8), FlSpot(9, 43.2),
    FlSpot(10, 43.6), FlSpot(11, 44.0), FlSpot(12, 44.3), FlSpot(15, 45.1),
    FlSpot(18, 45.8), FlSpot(21, 46.4), FlSpot(24, 46.9), FlSpot(27, 47.4),
    FlSpot(30, 47.8), FlSpot(33, 48.1), FlSpot(36, 48.4),
  ];

  // 第 25 百分位
  static const List<FlSpot> percentile25 = [
    FlSpot(0, 33.6), FlSpot(1, 36.5),
    FlSpot(2, 38.3), FlSpot(3, 39.7),
    FlSpot(4, 40.7), FlSpot(5, 41.5),
    FlSpot(6, 42.2), FlSpot(7, 42.7), FlSpot(8, 43.2), FlSpot(9, 43.7),
    FlSpot(10, 44.1), FlSpot(11, 44.5), FlSpot(12, 44.8), FlSpot(15, 45.6),
    FlSpot(18, 46.3), FlSpot(21, 46.9), FlSpot(24, 47.4), FlSpot(27, 47.9),
    FlSpot(30, 48.3), FlSpot(33, 48.6), FlSpot(36, 48.9),
  ];

  // 第 50 百分位
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 34.5), FlSpot(1, 37.3),
    FlSpot(2, 39.1), FlSpot(3, 40.5),
    FlSpot(4, 41.5), FlSpot(5, 42.4),
    FlSpot(6, 43.1), FlSpot(7, 43.6), FlSpot(8, 44.1), FlSpot(9, 44.6),
    FlSpot(10, 45.0), FlSpot(11, 45.4), FlSpot(12, 45.7), FlSpot(15, 46.5),
    FlSpot(18, 47.2), FlSpot(21, 47.8), FlSpot(24, 48.3), FlSpot(27, 48.8),
    FlSpot(30, 49.2), FlSpot(33, 49.5), FlSpot(36, 49.8),
  ];

  // 第 75 百分位
  static const List<FlSpot> percentile75 = [
    FlSpot(0, 35.3), FlSpot(1, 38.1),
    FlSpot(2, 39.9), FlSpot(3, 41.3),
    FlSpot(4, 42.3), FlSpot(5, 43.2),
    FlSpot(6, 44.0), FlSpot(7, 44.5), FlSpot(8, 45.0), FlSpot(9, 45.5),
    FlSpot(10, 45.9), FlSpot(11, 46.3), FlSpot(12, 46.6), FlSpot(15, 47.4),
    FlSpot(18, 48.1), FlSpot(21, 48.7), FlSpot(24, 49.2), FlSpot(27, 49.7),
    FlSpot(30, 50.1), FlSpot(33, 50.4), FlSpot(36, 50.7),
  ];

  // 第 85 百分位
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 35.8), FlSpot(1, 38.5),
    FlSpot(2, 40.3), FlSpot(3, 41.7),
    FlSpot(4, 42.7), FlSpot(5, 43.6),
    FlSpot(6, 44.4), FlSpot(7, 44.9), FlSpot(8, 45.4), FlSpot(9, 45.9),
    FlSpot(10, 46.3), FlSpot(11, 46.7), FlSpot(12, 47.0), FlSpot(15, 47.8),
    FlSpot(18, 48.5), FlSpot(21, 49.1), FlSpot(24, 49.6), FlSpot(27, 50.1),
    FlSpot(30, 50.5), FlSpot(33, 50.8), FlSpot(36, 51.1),
  ];

  // 第 97 百分位
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 36.9), FlSpot(1, 39.5),
    FlSpot(2, 41.3),  FlSpot(3, 42.7),
    FlSpot(4, 43.7), FlSpot(5, 44.6),
    FlSpot(6, 45.4), FlSpot(7, 45.9), FlSpot(8, 46.4), FlSpot(9, 46.9),
    FlSpot(10, 47.3), FlSpot(11, 47.7), FlSpot(12, 48.0), FlSpot(15, 48.8),
    FlSpot(18, 49.5), FlSpot(21, 50.1), FlSpot(24, 50.6), FlSpot(27, 51.1),
    FlSpot(30, 51.5), FlSpot(33, 51.8), FlSpot(36, 52.1),
  ];

// ✅ 修改 allPercentiles 列表，只保留 5 條線
  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}

/// 女孩頭圍成長曲線數據 (0-36個月) - 高密度平滑版
/// 數據來源：世界衛生組織 (WHO) & 美國CDC
/// 女孩頭圍成長曲線數據 (0-36個月) - WHO 官方修正版
class GirlHeadCircumferenceData {
  GirlHeadCircumferenceData._();

  // 第 3 百分位 (P3)
  static const List<FlSpot> percentile3 = [
    FlSpot(0, 31.7), FlSpot(1, 34.3), FlSpot(2, 36.0), FlSpot(3, 37.2),
    FlSpot(4, 38.2), FlSpot(5, 39.0), FlSpot(6, 39.7), FlSpot(7, 40.4),
    FlSpot(8, 40.9), FlSpot(9, 41.3), FlSpot(10, 41.7), FlSpot(11, 42.0),
    FlSpot(12, 42.3), FlSpot(15, 43.1), FlSpot(18, 43.6), FlSpot(21, 44.1),
    FlSpot(24, 44.6), FlSpot(27, 44.9), FlSpot(30, 45.3), FlSpot(33, 45.6),
    FlSpot(36, 45.9),
  ];

  // 第 15 百分位 (P15)
  static const List<FlSpot> percentile15 = [
    FlSpot(0, 32.7), FlSpot(1, 35.3), FlSpot(2, 37.0), FlSpot(3, 38.2),
    FlSpot(4, 39.3), FlSpot(5, 40.1), FlSpot(6, 40.8), FlSpot(7, 41.5),
    FlSpot(8, 42.0), FlSpot(9, 42.4), FlSpot(10, 42.8), FlSpot(11, 43.2),
    FlSpot(12, 43.5), FlSpot(15, 44.2), FlSpot(18, 44.8), FlSpot(21, 45.3),
    FlSpot(24, 45.7), FlSpot(27, 46.1), FlSpot(30, 46.5), FlSpot(33, 46.8),
    FlSpot(36, 47.0),
  ];

  // 第 50 百分位 (Median)
  static const List<FlSpot> percentile50 = [
    FlSpot(0, 33.9), FlSpot(1, 36.5), FlSpot(2, 38.3), FlSpot(3, 39.5),
    FlSpot(4, 40.6), FlSpot(5, 41.5), FlSpot(6, 42.2), FlSpot(7, 42.8),
    FlSpot(8, 43.4), FlSpot(9, 43.8), FlSpot(10, 44.2), FlSpot(11, 44.6),
    FlSpot(12, 44.9), FlSpot(15, 45.7), FlSpot(18, 46.2), FlSpot(21, 46.7),
    FlSpot(24, 47.2), FlSpot(27, 47.6), FlSpot(30, 47.9), FlSpot(33, 48.2),
    FlSpot(36, 48.5),
  ];

  // 第 85 百分位 (P85)
  static const List<FlSpot> percentile85 = [
    FlSpot(0, 35.1), FlSpot(1, 37.8), FlSpot(2, 39.5), FlSpot(3, 40.8),
    FlSpot(4, 41.9), FlSpot(5, 42.8), FlSpot(6, 43.5), FlSpot(7, 44.2),
    FlSpot(8, 44.7), FlSpot(9, 45.2), FlSpot(10, 45.6), FlSpot(11, 46.0),
    FlSpot(12, 46.3), FlSpot(15, 47.1), FlSpot(18, 47.7), FlSpot(21, 48.2),
    FlSpot(24, 48.6), FlSpot(27, 49.0), FlSpot(30, 49.4), FlSpot(33, 49.7),
    FlSpot(36, 50.0),
  ];

  // 第 97 百分位 (P97)
  static const List<FlSpot> percentile97 = [
    FlSpot(0, 36.1), FlSpot(1, 38.8), FlSpot(2, 40.5), FlSpot(3, 41.9),
    FlSpot(4, 43.0), FlSpot(5, 43.9), FlSpot(6, 44.6), FlSpot(7, 45.3),
    FlSpot(8, 45.9), FlSpot(9, 46.3), FlSpot(10, 46.8), FlSpot(11, 47.1),
    FlSpot(12, 47.5), FlSpot(15, 48.2), FlSpot(18, 48.8), FlSpot(21, 49.4),
    FlSpot(24, 49.8), FlSpot(27, 50.2), FlSpot(30, 50.6), FlSpot(33, 50.9),
    FlSpot(36, 51.2),
  ];

  static const List<List<FlSpot>> allPercentiles = [
    percentile3,
    percentile15,
    percentile50,
    percentile85,
    percentile97,
  ];
}