import 'package:isar/isar.dart';
import 'package:shopsync/features/orders/data/addon_model.dart';
import 'package:shopsync/features/backup/data/backup_service.dart';

class AddonRepository {
  final Isar isar;
  final BackupService backupService;

  AddonRepository(this.isar, this.backupService) {
    _prepopulateDefaults();
  }

  Future<void> _prepopulateDefaults() async {
    final count = await isar.addons.count();
    if (count == 0) {
      final defaults = [
        Addon()
          ..name = 'Delivery'
          ..price = 100.0
          ..cost = 50.0,
        Addon()
          ..name = 'Packaging'
          ..price = 50.0
          ..cost = 20.0,
        Addon()
          ..name = 'Gift Wrap'
          ..price = 30.0
          ..cost = 10.0,
        Addon()
          ..name = 'Customization'
          ..price = 150.0
          ..cost = 80.0,
      ];
      await isar.writeTxn(() async {
        await isar.addons.putAll(defaults);
      });
    }
  }

  Future<List<Addon>> getAllAddons() async {
    return await isar.addons.filter().isVoidEqualTo(false).findAll();
  }

  Future<void> saveAddon(Addon addon) async {
    await isar.writeTxn(() async {
      await isar.addons.put(addon);
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Future<void> voidAddon(Id id) async {
    await isar.writeTxn(() async {
      final addon = await isar.addons.get(id);
      if (addon != null) {
        addon.isVoid = true;
        await isar.addons.put(addon);
      }
    });
    await backupService.markLocalChanged();
    backupService.autoBackupIfPossible();
  }

  Stream<List<Addon>> watchAddons() {
    return isar.addons
        .filter()
        .isVoidEqualTo(false)
        .watch(fireImmediately: true);
  }
}
