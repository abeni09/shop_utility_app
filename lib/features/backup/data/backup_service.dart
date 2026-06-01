import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  final Isar isar;

  // v6.x: Simple constructor-based configuration with scopes.
  // This is the reliable API that properly persists sessions on Android.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  String? _cachedEmail;
  String? get cachedEmail => _cachedEmail;

  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  BackupService(this.isar) {
    // Listen for sign-in/out to keep cache in sync
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      _saveSession(account?.email);
    });

    // Load the locally cached email for instant UI
    _loadSession();

    // Silently restore the real Google session in background
    Future.microtask(() async {
      try {
        await _googleSignIn.signInSilently();
      } catch (e) {
        // Silence — only triggers on explicit user action
      }
    });
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedEmail = prefs.getString('backup_user_email');
  }

  Future<String?> getLastSyncedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_synced_id');
  }

  Future<void> _setLastSyncedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_synced_id', id);
    // When we sync with the cloud, local is no longer ahead
    await prefs.setInt(
      'last_backed_up_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> markLocalChanged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_local_change_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> isLocalAhead() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChange = prefs.getInt('last_local_change_time') ?? 0;
    final lastBackup = prefs.getInt('last_backed_up_time') ?? 0;
    return lastChange > lastBackup;
  }

  /// Checks if the cloud has a newer/different backup than the local one.
  Future<bool> isCloudNewer() async {
    try {
      final client = await _getAuthClient();
      if (client == null) return false;

      final driveApi = drive.DriveApi(client);
      final fileList = await driveApi.files.list(
        q: "name contains 'ShopSync_Backup_' and trashed = false",
        orderBy: 'createdTime desc',
        pageSize: 1,
      );

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final latestFileId = fileList.files!.first.id;
      final localSyncedId = await getLastSyncedId();

      // If the cloud file ID is different from what we last synced, it's "newer"
      return latestFileId != null && latestFileId != localSyncedId;
    } catch (e) {
      print('Sync check error: $e');
      return false;
    }
  }

  /// Manually triggers a check for cloud updates and local pending changes.
  /// Typically called from "Pull to Refresh" UI.
  Future<void> forceSyncCheck() async {
    try {
      // Re-sign in silently to ensure valid token
      await _googleSignIn.signInSilently();

      // These getters will naturally refresh because the underlying
      // SharedPreferences and Google session are used.
      await isCloudNewer();
      await isLocalAhead();
    } catch (e) {
      print('Manual sync check failed: $e');
    }
  }

  Future<void> _saveSession(String? email) async {
    _cachedEmail = email;
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString('backup_user_email', email);
    } else {
      await prefs.remove('backup_user_email');
    }
  }

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<http.Client?> _getAuthClient() async {
    // Try silent first, then interactive
    GoogleSignInAccount? account = await _googleSignIn.signInSilently();
    if (account == null) {
      account = await _googleSignIn.signIn();
    }
    if (account == null) return null;
    return await _googleSignIn.authenticatedClient();
  }

  Future<void> uploadBackup({bool forceSignIn = false}) async {
    try {
      http.Client? client;
      if (forceSignIn) {
        client = await _getAuthClient();
      } else {
        // Non-interactive: only use already-signed-in session
        final account = await _googleSignIn.signInSilently();
        if (account == null) return;
        client = await _googleSignIn.authenticatedClient();
      }

      if (client == null) {
        if (forceSignIn) throw Exception('Please sign in to backup data.');
        return;
      }

      final driveApi = drive.DriveApi(client);
      final dir = await getApplicationDocumentsDirectory();
      final backupFile = File('${dir.path}/temp_backup.isar');

      if (await backupFile.exists()) await backupFile.delete();
      await isar.copyToFile(backupFile.path);

      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'ShopSync_Backup_$dateStr.isar';

      final existingFiles = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        pageSize: 1,
      );

      final media = drive.Media(
        backupFile.openRead(),
        await backupFile.length(),
      );
      String? fileId;

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        final existingFile = existingFiles.files!.first;
        final updatedFile = await driveApi.files.update(
          drive.File(),
          existingFile.id!,
          uploadMedia: media,
        );
        fileId = updatedFile.id;
      } else {
        final driveFile = drive.File()..name = fileName;
        final uploadedFile = await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
        fileId = uploadedFile.id;
      }

      if (fileId != null) {
        await _setLastSyncedId(fileId);
      }

      await backupFile.delete();
    } catch (e) {
      if (forceSignIn) rethrow;
      print('Backup upload error: $e');
    }
  }

  Future<void> autoBackupIfPossible() async {
    uploadBackup().catchError((e) => print('Auto-backup failed: $e'));
  }

  Future<void> restoreLatestBackup() async {
    try {
      final client = await _getAuthClient();
      if (client == null) throw Exception('Sign-in required for restoration.');

      final driveApi = drive.DriveApi(client);

      final fileList = await driveApi.files.list(
        q: "name contains 'ShopSync_Backup_' and trashed = false",
        orderBy: 'createdTime desc',
        pageSize: 1,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception('No backup files found on Google Drive.');
      }

      final fileId = fileList.files!.first.id!;

      final drive.Media media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final dir = await getApplicationDocumentsDirectory();
      final tempFile = File('${dir.path}/temp_restore.isar');

      final sink = tempFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      final dbPath = '${dir.path}/shopsync_db.isar';
      await tempFile.copy(dbPath);
      await tempFile.delete();

      await _setLastSyncedId(fileId);
    } catch (e) {
      print('Restore error: $e');
      rethrow;
    }
  }
}
