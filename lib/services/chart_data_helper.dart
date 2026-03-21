// lib/services/chart_data_helper.dart
class ChartDataHelper {
  static List<PoemRecord> filterRecords({
    required List<PoemRecord> all,
    required ScaleType type,
    required int days,
    DateTimeRange? customRange,
  }) {
    List<PoemRecord> filtered = all.where((r) {
      final date = r.targetDate ?? r.date;
      if (date == null || r.scaleType != type) return false;

      if (days == -1 && customRange != null) {
        return date.isAfter(customRange.start) && date.isBefore(customRange.end);
      }
      return DateTime.now().difference(date).inDays <= (days - 1);
    }).toList();

    return filtered..sort((a, b) => (a.targetDate ?? a.date!).compareTo(b.targetDate ?? b.date!));
  }
}