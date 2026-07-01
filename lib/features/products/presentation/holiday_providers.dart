import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/presentation/backup_providers.dart';
import 'package:shopsync/features/products/data/holiday_model.dart';
import 'package:shopsync/features/products/data/holiday_repository.dart';
import 'package:shopsync/main.dart';

final holidayRepositoryProvider = Provider<HolidayRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final backupService = ref.watch(backupServiceProvider);
  return HolidayRepository(dbService.isar, backupService);
});

final holidaysProvider = StreamProvider<List<Holiday>>((ref) {
  final repository = ref.watch(holidayRepositoryProvider);
  return repository.watchHolidays();
});
