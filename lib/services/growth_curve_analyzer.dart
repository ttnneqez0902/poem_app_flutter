import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/growth_curve_data.dart';

class GrowthCurveAnalyzer {
  /// 獲取 WHO 背景百分位參考線
  /// 將月齡座標系統轉換為以 [startDate] 為基準的天數座標系統
  static List<LineChartBarData> getBackgroundLines({
    required DateTime startDate,
    required DateTime? birthday,
    required bool isBoy,
    required String mode,
    required int selectedDays,
  }) {
    // 🚀 1. 防禦性編程：若無生日，無法計算月齡偏移，不顯示背景線
    if (birthday == null) return [];

    // 🚀 2. 計算偏移量：圖表起點 (X=0) 對應寶寶出生後的第幾天
    // 例如：寶寶 100 天大時開始畫圖，那圖表的 0 點對應 WHO 數據的第 100 天
    final double daysFromBirthToChartStart = startDate.difference(birthday).inDays.toDouble();

    // 🚀 3. 根據性別與模式（身高/體重/頭圍）抓取對應的 WHO 原始數據
    List<List<FlSpot>> rawPercentileData;

    if (mode == 'weight') {
      rawPercentileData = isBoy ? BoyWeightData.allPercentiles : GirlWeightData.allPercentiles;
    } else if (mode == 'head') {
      rawPercentileData = isBoy ? BoyHeadCircumferenceData.allPercentiles : GirlHeadCircumferenceData.allPercentiles;
    } else {
      // 預設身高
      rawPercentileData = isBoy ? BoyHeightData.allPercentiles : GirlHeightData.allPercentiles;
    }

    // 🚀 4. 進行座標轉換並生成 LineChartBarData
    return rawPercentileData.map((spots) {
      return LineChartBarData(
        spots: spots.map((s) {
          // 將 WHO 原始月齡 (s.x) 轉換為天數 (s.x * 30.4375)
          // 然後減去偏移量，使其對齊圖表的 X 軸 (以天為單位)
          double dayX = (s.x * 30.4375) - daysFromBirthToChartStart;
          return FlSpot(dayX, s.y);
        }).where((s) {
          // 🚀 5. 效能優化：只保留在畫面顯示範圍內（前後各留 30 天緩衝）的點位
          // 這樣 Pixel 9 Pro 就不需要渲染三整年份的背景數據，滑動會極度流暢
          return s.x >= -30 && s.x <= (selectedDays == -1 ? 365 : selectedDays) + 30;
        }).toList(),

        // 🚀 6. 視覺風格設定：背景參考線必須淡化，不喧賓奪主
        isCurved: true,
        curveSmoothness: 0.1,
        color: Colors.grey.withOpacity(0.15), // 極淡灰
        barWidth: 1.2,                      // 極細
        dashArray: [5, 5],                  // 虛線感
        dotData: const FlDotData(show: false), // 不顯示圓點
        belowBarData: BarAreaData(show: false), // 不填滿顏色
      );
    }).toList();
  }

  /// 計算當前數據所處的百分位 (可選：未來可增加此功能返回字串如 "P50")
  static String calculatePercentileLabel(double ageInMonths, double value, bool isBoy, String mode) {
    // 這裡未來可以實作離散數據插值，算出寶寶目前精確的百分位數
    return "";
  }
}