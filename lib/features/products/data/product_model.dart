import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late double costPrice;
  late double sellingPrice;

  int? supplierId;

  DateTime? lastUpdated;

  bool isVoid = false;

  int minStockThreshold = 5;

  int shelfLifeDays = 30;

  bool hasQuota = false;
  double? weekdayQuota;
  double? weekendQuota;
  double? holidayQuota;
  double? overQuotaCostPrice;

  double getQuotaForDate(DateTime date, List<DateTime> holidayDates) {
    if (!hasQuota) return double.infinity;
    
    // Normalize date to compare
    final startOfDay = DateTime(date.year, date.month, date.day);
    
    final isHoliday = holidayDates.any((h) =>
        h.year == startOfDay.year &&
        h.month == startOfDay.month &&
        h.day == startOfDay.day);
        
    if (isHoliday) {
      return holidayQuota ?? weekdayQuota ?? 0.0;
    }
    
    if (startOfDay.weekday == DateTime.saturday || startOfDay.weekday == DateTime.sunday) {
      return weekendQuota ?? weekdayQuota ?? 0.0;
    }
    
    return weekdayQuota ?? 0.0;
  }
  
  double calculateCostForQuantity(double quantity, double quotaLimit) {
    if (quantity <= 0) return 0.0;
    if (quantity <= quotaLimit) {
      return quantity * costPrice;
    } else {
      final baseCost = quotaLimit * costPrice;
      final penaltyCost = (quantity - quotaLimit) * (overQuotaCostPrice ?? costPrice);
      return baseCost + penaltyCost;
    }
  }
}
