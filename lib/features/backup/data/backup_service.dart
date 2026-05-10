import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart' as auth;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  final Isar isar;
  final auth.GoogleSignIn _googleSignIn = auth.GoogleSignIn.instance;

  BackupService(this.isar);

  auth.GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  Stream<auth.GoogleSignInAccount?> get onCurrentUserChanged => _googleSignIn.onCurrentUserChanged;

  Future<bool> signIn() async {
    try {
      await _googleSignIn.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope],
      );
      return true;
    } catch (e) {
      print('Backup sign-in error: $e');
      return false;
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
      final backupFile = File('${dir.path}/shop_backup.isar');

      // Create a temporary copy of the DB for backup
      // Note: copyToFile requires the file NOT to exist
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
    final account = await _googleSignIn.attemptLightweightAuthentication();
    if (account != null) {
      await uploadBackup();
    }
  }
}
