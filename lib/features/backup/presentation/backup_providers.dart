import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/main.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BackupService(dbService.isar);
});
