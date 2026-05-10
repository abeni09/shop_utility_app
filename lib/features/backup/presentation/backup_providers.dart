import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/main.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BackupService(dbService.isar);
});

final backupUserProvider = StreamProvider((ref) {
  final service = ref.watch(backupServiceProvider);
  // Re-emit whenever sign in status changes
  // Note: auth.GoogleSignIn has onCurrentUserChanged stream
  // Since BackupService doesn't expose it directly yet, I'll use a trick or just expose it.
  return ref.watch(backupServiceProvider).onCurrentUserChanged;
});
