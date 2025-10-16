// services/device_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_unique_id';

  // Obter ou criar DeviceId único e persistente
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Criar novo ID único
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      await prefs.setString(_deviceIdKey, deviceId);
      print('📱 [DEVICE] Novo DeviceId criado: $deviceId');
    } else {
      print('📱 [DEVICE] DeviceId recuperado: $deviceId');
    }

    return deviceId;
  }

  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(DateTime.now().microsecond % chars.length),
      ),
    );
  }
}
