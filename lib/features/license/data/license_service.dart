import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class LicenseService {
  static const String _apiEndpoint = 'https://api.yourdomain.com/license/activate';
  static const String _salt = 'ShopSyncSecuritySalt2026';

  // Local storage keys
  static const String _keyDeviceId = 'ss_license_device_id';
  static const String _keyLicenseKey = 'ss_license_key';
  static const String _keyExpiry = 'ss_license_expiry';
  static const String _keyChecksum = 'ss_license_checksum';
  static const String _keyLastOpened = 'ss_license_last_opened';

  // Get or create unique device ID
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null) {
      // Create a clean readable device ID like SS-XXXX-XXXX
      final uuid = const Uuid().v4().toUpperCase().replaceAll('-', '');
      deviceId = 'SS-${uuid.substring(0, 4)}-${uuid.substring(4, 8)}';
      await prefs.setString(_keyDeviceId, deviceId);
    }
    return deviceId;
  }

  // Get current system clock tampering state
  Future<bool> isClockTampered() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastOpenedStr = prefs.getString(_keyLastOpened);
    if (lastOpenedStr == null) {
      await prefs.setString(_keyLastOpened, now.toIso8601String());
      return false;
    }

    final lastOpened = DateTime.parse(lastOpenedStr);
    if (now.isBefore(lastOpened)) {
      // System clock was rolled back
      return true;
    }

    // Save the new current time for future checks
    await prefs.setString(_keyLastOpened, now.toIso8601String());
    return false;
  }

  // Generate checksum to prevent manual shared preferences editing
  String _calculateChecksum(String key, String expiry, String deviceId) {
    final payload = '$key|$expiry|$deviceId|$_salt';
    final bytes = utf8.encode(payload);
    return sha256.convert(bytes).toString();
  }

  // Check if license is active and valid locally
  Future<bool> isLicenseValid() async {
    try {
      if (await isClockTampered()) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_keyLicenseKey);
      final expiryStr = prefs.getString(_keyExpiry);
      final checksum = prefs.getString(_keyChecksum);
      final deviceId = await getDeviceId();

      if (key == null || expiryStr == null || checksum == null) {
        return false;
      }

      // Verify checksum integrity
      final expectedChecksum = _calculateChecksum(key, expiryStr, deviceId);
      if (checksum != expectedChecksum) {
        return false; // Storage was tampered with
      }

      // Check date
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiry)) {
        return false; // Expired
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  // Get expiry date
  Future<DateTime?> getExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyExpiry);
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }

  // Get current key
  Future<String?> getLicenseKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLicenseKey);
  }

  // Reset/Clear local license (useful for testing or revocation)
  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLicenseKey);
    await prefs.remove(_keyExpiry);
    await prefs.remove(_keyChecksum);
  }

  // Call the server to activate the license key
  Future<Map<String, dynamic>> activate(String key) async {
    final deviceId = await getDeviceId();
    final trimmedKey = key.trim().toUpperCase();

    try {
      // Special offline activation bypass for offline demo and testing:
      if (trimmedKey == 'DEMO-1234-5678') {
        final expiry = DateTime.now().add(const Duration(days: 365));
        await saveLicenseLocally(trimmedKey, expiry);
        return {
          'success': true,
          'expiry': expiry.toIso8601String(),
          'message': 'Demo license activated successfully!'
        };
      }

      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': trimmedKey,
          'device_id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final expiryStr = data['expiry_date'];
          final expiry = DateTime.parse(expiryStr);
          await saveLicenseLocally(trimmedKey, expiry);
          return {
            'success': true,
            'expiry': expiry.toIso8601String(),
            'message': data['message'] ?? 'Activated successfully!'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid license key.'
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode}). Please try again later.'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please connect to the internet to activate.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error activating: $e'
      };
    }
  }

  // Save the license details locally
  Future<void> saveLicenseLocally(String key, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();
    final expiryStr = expiry.toIso8601String();
    final checksum = _calculateChecksum(key, expiryStr, deviceId);

    await prefs.setString(_keyLicenseKey, key);
    await prefs.setString(_keyExpiry, expiryStr);
    await prefs.setString(_keyChecksum, checksum);
  }
}
