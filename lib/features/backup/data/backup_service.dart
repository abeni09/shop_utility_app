import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  final Isar isar;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  BackupService(this.isar);

  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.authenticate(
        scopeHint: [drive.DriveApi.driveFileScope],
      );
      
      // Explicitly authorize the Drive scope
      await account.authorizationClient.authorizeScopes([drive.DriveApi.driveFileScope]);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> uploadBackup() async {
    final account = await (_googleSignIn.attemptLightweightAuthentication() ??
        Future.value(null));
    if (account == null) {
      throw Exception('Not signed in');
    }

    final authz = await account.authorizationClient
            .authorizationForScopes([drive.DriveApi.driveFileScope]) ??
        await account.authorizationClient
            .authorizeScopes([drive.DriveApi.driveFileScope]);

    final httpClient =
        authz.authClient(scopes: [drive.DriveApi.driveFileScope]);
    final driveApi = drive.DriveApi(httpClient);

    final dir = await getApplicationDocumentsDirectory();
    final backupFile = File('${dir.path}/shop_backup.isar');

    // Create a temporary copy of the DB for backup
    await isar.copyToFile(backupFile.path);

    final driveFile = drive.File();
    driveFile.name =
        "shop_utility_backup_${DateTime.now().toIso8601String()}.isar";

    final media = drive.Media(backupFile.openRead(), backupFile.lengthSync());
    await driveApi.files.create(driveFile, uploadMedia: media);

    // Clean up local temp file
    await backupFile.delete();
  }

  Future<void> autoBackupIfPossible() async {
    final account = await (_googleSignIn.attemptLightweightAuthentication() ??
        Future.value(null));
    if (account != null) {
      await uploadBackup();
    }
  }
}
