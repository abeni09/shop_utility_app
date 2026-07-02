import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsync/features/license/data/license_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LicenseService Tests', () {
    test('Device ID is generated and persisted', () async {
      final service = LicenseService();
      final id1 = await service.getDeviceId();
      final id2 = await service.getDeviceId();

      expect(id1, isNotEmpty);
      expect(id1.startsWith('SS-'), true);
      expect(id1, equals(id2)); // Must remain consistent
    });

    test('Clock tamper guard detects rollback', () async {
      final service = LicenseService();
      expect(await service.isClockTampered(), false);

      // Save a future date as last opened
      final prefs = await SharedPreferences.getInstance();
      final futureDate = DateTime.now().add(const Duration(days: 10));
      await prefs.setString('ss_license_last_opened', futureDate.toIso8601String());

      // Should now detect clock tamper (since current time is before saved last opened)
      expect(await service.isClockTampered(), true);
    });

    test('Local license checksum verification works', () async {
      final service = LicenseService();
      
      // Before activation
      expect(await service.isLicenseValid(), false);
      expect(await service.getLicenseKey(), isNull);

      // Activate locally
      final expiry = DateTime.now().add(const Duration(days: 365));
      await service.saveLicenseLocally('TEST-KEY-1234', expiry);

      expect(await service.isLicenseValid(), true);
      expect(await service.getLicenseKey(), 'TEST-KEY-1234');
      expect(await service.getExpiryDate(), isNotNull);

      // Manually tamper with the storage values without updating checksum
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ss_license_expiry', DateTime.now().add(const Duration(days: 500)).toIso8601String());

      // Verification should fail due to checksum mismatch
      expect(await service.isLicenseValid(), false);
    });

    test('Expired license is invalid', () async {
      final service = LicenseService();
      
      final expiry = DateTime.now().subtract(const Duration(days: 1));
      await service.saveLicenseLocally('EXPIRED-KEY', expiry);

      expect(await service.isLicenseValid(), false);
    });
  });
}
