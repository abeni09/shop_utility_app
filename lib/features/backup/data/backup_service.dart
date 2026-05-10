import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart' as auth;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  final Isar isar;
  final auth.GoogleSignIn _googleSignIn = auth.GoogleSignIn.instance;

  auth.GoogleSignInAccount? _currentUser;
  auth.GoogleSignInAccount? get currentUser => _currentUser;

  Stream<auth.GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.authenticationEvents.map((event) {
        if (event is auth.GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          return event.user;
        } else {
          _currentUser = null;
          return null;
        }
      });

  BackupService(this.isar) {
    // Explicitly initialize with the Web Client ID from google-services.json
    // to bypass the plugin's auto-detection issues on Android.
    _googleSignIn.initialize(
      serverClientId: '461920714778-tr1c97t16546jc2dd2isfosv9t88nh33.apps.googleusercontent.com',
    );

    _googleSignIn.authenticationEvents.listen((event) {
      if (event is auth.GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
      } else if (event is auth.GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
      }
    }, onError: (e) {
      print('Backup authentication stream error: $e');
    });

    // Attempt to restore sign-in silently without crashing the build
    Future.microtask(() async {
      try {
        await _googleSignIn.attemptLightweightAuthentication();
      } catch (e) {
        print('Initial backup auth attempt failed: $e');
      }
    });
  }

  Future<bool> signIn() async {
    // Re-initialize/verify if needed (optional but good for safety)
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope],
      );
      return account != null;
    } catch (e) {
      // Re-throw to let the UI catch and display the error
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> uploadBackup() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication() ??
          await _googleSignIn.authenticate(
            scopeHint: [drive.DriveApi.driveFileScope],
          );

      final authz = await account.authorizationClient.authorizeScopes([
        drive.DriveApi.driveFileScope,
      ]);

      final authClient = authz.authClient(
        scopes: [drive.DriveApi.driveFileScope],
      );

      final driveApi = drive.DriveApi(authClient);

      final dir = await getApplicationDocumentsDirectory();
      final backupFile = File('${dir.path}/temp_backup.isar');

      // Create a temporary copy of the DB for backup
      if (await backupFile.exists()) await backupFile.delete();
      await isar.copyToFile(backupFile.path);

      final driveFile = drive.File();
      driveFile.name = "ShopSync_Backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.isar";
      // We'll put it in appDataFolder or just drive for now
      
      final media = drive.Media(backupFile.openRead(), await backupFile.length());
      await driveApi.files.create(driveFile, uploadMedia: media);

      // Clean up local temp file
      await backupFile.delete();
    } catch (e) {
      print('Backup upload error: $e');
      rethrow;
    }
  }

  Future<void> autoBackupIfPossible() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      if (account != null) {
        // Run upload in background without blocking
        uploadBackup().catchError((e) => print('Background backup failed: $e'));
      }
    } catch (e) {
      print('Auto-backup check failed: $e');
    }
  }

  Future<void> restoreLatestBackup() async {
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication() ??
          await _googleSignIn.authenticate(
            scopeHint: [drive.DriveApi.driveFileScope],
          );

      final authz = await account.authorizationClient.authorizeScopes([
        drive.DriveApi.driveFileScope,
      ]);

      final authClient = authz.authClient(
        scopes: [drive.DriveApi.driveFileScope],
      );

      final driveApi = drive.DriveApi(authClient);

      // 1. List backup files
      final fileList = await driveApi.files.list(
        q: "name contains 'ShopSync_Backup_' and trashed = false",
        orderBy: "createdTime desc",
        pageSize: 1,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        throw Exception("No backup files found on Google Drive.");
      }

      final latestFile = fileList.files!.first;
      final fileId = latestFile.id!;

      // 2. Download the file
      final drive.Media response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.metadata,
      ) as drive.Media; // This gets metadata, we need media

      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final dir = await getApplicationDocumentsDirectory();
      final tempFile = File('${dir.path}/temp_restore.isar');
      
      final ios = tempFile.openWrite();
      await media.stream.pipe(ios);
      await ios.close();

      // 3. Replace local DB
      final dbPath = '${dir.path}/shopsync_db.isar'; 
      
      await tempFile.copy(dbPath);
      await tempFile.delete();
      
    } catch (e) {
      print('Restore error: $e');
      rethrow;
    }
  }
}
