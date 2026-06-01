import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';
import 'package:shopsync/main.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return BackupService(dbService.isar);
});

final backupUserProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final service = ref.watch(backupServiceProvider);
  return service.onCurrentUserChanged;
});

// Provides the sync status (true if cloud has a newer file)
final cloudSyncStatusProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(backupUserProvider).value;
  if (user == null) return false;

  final service = ref.watch(backupServiceProvider);
  return service.isCloudNewer();
});

// Provides true if local has changes that haven't been backed up
final localAheadProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(backupUserProvider).value;
  if (user == null) return false;

  final service = ref.watch(backupServiceProvider);
  return service.isLocalAhead();
});
