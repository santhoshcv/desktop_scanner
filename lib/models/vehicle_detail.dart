//lib/models/vehicle_detail.dart =====
class VehicleDetail {
  final String vehicleNumber;
  final String chassisNumber;
  final String year;
  final String make;
  final String ownerNameEnglish;
  final String ownerNameArabic;
  final String ownerId;
  final String vehicleType;
  final String expiryDate;
  final String? platformExpiryDate; // NEW field

  VehicleDetail({
    required this.vehicleNumber,
    required this.chassisNumber,
    required this.year,
    required this.make,
    required this.ownerNameEnglish,
    required this.ownerNameArabic,
    required this.ownerId,
    required this.vehicleType,
    required this.expiryDate,
    this.platformExpiryDate, // NEW
  });

  factory VehicleDetail.fromApiResponse(
    String response,
    Map<String, String> vehicleTypeTranslations,
  ) {
    // Simplified vehicle type extraction - only tipper or trailer
    String vehicleType = 'NAN';

    // Check for various indicators of vehicle type
    final lowerResponse = response.toLowerCase();

    if (lowerResponse.contains('tipper') ||
        lowerResponse.contains('نشال') ||
        lowerResponse.contains('قلاب')) {
      vehicleType = 'tipper';
    } else if (lowerResponse.contains('trailer') ||
        lowerResponse.contains('تريلا') ||
        lowerResponse.contains('رأس')) {
      vehicleType = 'trailer';
    }

    return VehicleDetail(
      vehicleNumber: _extractField(response, 'vehicle_number'),
      chassisNumber: _extractField(response, 'chassis_number'),
      year: _extractField(response, 'year'),
      make: _extractField(response, 'make'),
      ownerNameEnglish: _extractField(response, 'owner_name_english'),
      ownerNameArabic: _extractField(response, 'owner_name_arabic'),
      ownerId: _extractField(response, 'owner_id'),
      vehicleType: vehicleType,
      expiryDate: _extractField(response, 'expiry_date'),
      platformExpiryDate: null, // Will be set later from platform service
    );
  }

  static String _extractField(String response, String fieldName) {
    final match = RegExp(
      '"$fieldName":\\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(response);
    return match?.group(1) ?? 'NAN';
  }

  // Copy with platform expiry
  VehicleDetail copyWithPlatformExpiry(String? platformExpiry) {
    return VehicleDetail(
      vehicleNumber: vehicleNumber,
      chassisNumber: chassisNumber,
      year: year,
      make: make,
      ownerNameEnglish: ownerNameEnglish,
      ownerNameArabic: ownerNameArabic,
      ownerId: ownerId,
      vehicleType: vehicleType,
      expiryDate: expiryDate,
      platformExpiryDate: platformExpiry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_number': vehicleNumber,
      'chassis_number': chassisNumber,
      'year': year,
      'make': make,
      'owner_name_english': ownerNameEnglish,
      'owner_name_arabic': ownerNameArabic,
      'owner_id': ownerId,
      'vehicle_type': vehicleType,
      'expiry_date': expiryDate,
      'platform_expiry_date': platformExpiryDate, // NEW
    };
  }
}
