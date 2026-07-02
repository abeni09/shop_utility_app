import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsync/features/license/data/license_service.dart';

enum LicenseStatus {
  checking,
  active,
  expired,
  clockTampered,
  notActivated,
}

class LicenseState {
  final LicenseStatus status;
  final String? deviceId;
  final String? licenseKey;
  final DateTime? expiryDate;
  final String? errorMessage;

  LicenseState({
    required this.status,
    this.deviceId,
    this.licenseKey,
    this.expiryDate,
    this.errorMessage,
  });

  LicenseState copyWith({
    LicenseStatus? status,
    String? deviceId,
    String? licenseKey,
    DateTime? expiryDate,
    String? errorMessage,
  }) {
    return LicenseState(
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
      licenseKey: licenseKey ?? this.licenseKey,
      expiryDate: expiryDate ?? this.expiryDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final licenseServiceProvider = Provider<LicenseService>((ref) {
  return LicenseService();
});

class LicenseNotifier extends StateNotifier<LicenseState> {
  final LicenseService _service;

  LicenseNotifier(this._service) : super(LicenseState(status: LicenseStatus.checking)) {
    checkLicense();
  }

  Future<void> checkLicense() async {
    state = state.copyWith(status: LicenseStatus.checking);
    
    final deviceId = await _service.getDeviceId();
    final isTampered = await _service.isClockTampered();
    
    if (isTampered) {
      state = LicenseState(
        status: LicenseStatus.clockTampered,
        deviceId: deviceId,
        errorMessage: 'System clock tampering detected. Please restore your correct date and time.',
      );
      return;
    }

    final isValid = await _service.isLicenseValid();
    final expiry = await _service.getExpiryDate();
    final key = await _service.getLicenseKey();

    if (isValid && key != null) {
      state = LicenseState(
        status: LicenseStatus.active,
        deviceId: deviceId,
        licenseKey: key,
        expiryDate: expiry,
      );
      // Run remote status sync in the background
      _performBackgroundCheck(key);
    } else {
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        state = LicenseState(
          status: LicenseStatus.expired,
          deviceId: deviceId,
          licenseKey: key,
          expiryDate: expiry,
          errorMessage: 'Your yearly subscription has expired.',
        );
      } else {
        state = LicenseState(
          status: LicenseStatus.notActivated,
          deviceId: deviceId,
        );
      }
    }
  }

  Future<void> _performBackgroundCheck(String key) async {
    final result = await _service.checkRemoteStatus();
    final status = result['status'];
    
    if (status == 'revoked' || status == 'invalid') {
      // License key deactivated/revoked by admin
      await _service.clearLicense();
      final deviceId = await _service.getDeviceId();
      state = LicenseState(
        status: LicenseStatus.notActivated,
        deviceId: deviceId,
        errorMessage: result['message'] ?? 'This license key has been deactivated.',
      );
    } else if (status == 'expired') {
      // Subscription expired
      await _service.clearLicense();
      final deviceId = await _service.getDeviceId();
      final expiryStr = result['expiry_date'];
      final expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;
      state = LicenseState(
        status: LicenseStatus.expired,
        deviceId: deviceId,
        licenseKey: key,
        expiryDate: expiry,
        errorMessage: result['message'] ?? 'Your subscription has expired.',
      );
    } else if (status == 'active') {
      // Key active, sync expiry date if changed on the server
      final expiryStr = result['expiry_date'];
      if (expiryStr != null) {
        final remoteExpiry = DateTime.parse(expiryStr);
        final localExpiry = await _service.getExpiryDate();
        if (localExpiry == null || !localExpiry.isAtSameMomentAs(remoteExpiry)) {
          await _service.saveLicenseLocally(key, remoteExpiry);
          state = state.copyWith(expiryDate: remoteExpiry);
        }
      }
    }
  }

  Future<bool> activate(String key) async {
    state = state.copyWith(status: LicenseStatus.checking);
    final result = await _service.activate(key);
    
    if (result['success'] == true) {
      await checkLicense();
      return true;
    } else {
      final deviceId = await _service.getDeviceId();
      state = LicenseState(
        status: LicenseStatus.notActivated,
        deviceId: deviceId,
        errorMessage: result['message'],
      );
      return false;
    }
  }

  Future<void> deactivate() async {
    await _service.clearLicense();
    await checkLicense();
  }
}

final licenseStateProvider = StateNotifierProvider<LicenseNotifier, LicenseState>((ref) {
  final service = ref.watch(licenseServiceProvider);
  return LicenseNotifier(service);
});
