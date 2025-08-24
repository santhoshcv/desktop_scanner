// ===== 3. NEW FILE: lib/services/platform_service.dart =====
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_settings.dart';
import '../models/platform_vehicle.dart';

class PlatformService {
  static PlatformService? _instance;
  static PlatformService get instance => _instance ??= PlatformService._();
  PlatformService._();

  final Map<String, PlatformVehicle> _vehicleMap = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  Map<String, PlatformVehicle> get vehicles => _vehicleMap;

  // Normalize plate number for comparison (remove leading zeros)
  String _normalizePlate(String plate) {
    // Remove any non-numeric characters and leading zeros
    String cleaned = plate.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.replaceFirst(RegExp(r'^0+'), '');
  }

  Future<void> loadVehicles() async {
    final settings = AppSettings.instance;

    if (settings.platformApiUrl.isEmpty) {
      print('Platform API URL not configured');
      _isLoaded = true; // Mark as loaded even if empty
      return;
    }

    try {
      final response = await http.get(Uri.parse(settings.platformApiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        _vehicleMap.clear();

        for (var item in jsonData) {
          try {
            final vehicle = PlatformVehicle.fromJson(item);
            // Store with normalized plate number as key
            final normalizedPlate = _normalizePlate(vehicle.plateNumber);
            if (normalizedPlate.isNotEmpty) {
              _vehicleMap[normalizedPlate] = vehicle;
            }
          } catch (e) {
            print('Error parsing vehicle: $e');
          }
        }

        _isLoaded = true;
        print('Loaded ${_vehicleMap.length} vehicles from platform API');
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading platform vehicles: $e');
      _isLoaded = true; // Mark as loaded to prevent repeated attempts
    }
  }

  // Get platform expiry date for a vehicle by plate number
  String? getPlatformExpiry(String plateNumber) {
    if (_vehicleMap.isEmpty) return null;

    final normalizedPlate = _normalizePlate(plateNumber);
    final vehicle = _vehicleMap[normalizedPlate];

    return vehicle?.formattedExpiryDate;
  }

  // Reload vehicles (useful after settings change)
  Future<void> reloadVehicles() async {
    _isLoaded = false;
    await loadVehicles();
  }
}
