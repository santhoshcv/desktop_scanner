//lib/models/vehicle_detail.dart

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
  });

  factory VehicleDetail.fromApiResponse(
    String response,
    Map<String, String> vehicleTypeTranslations,
  ) {
    String vehicleType = 'NAN';

    final vehicleTypeMatch = RegExp(
      r'"vehicle_type":\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(response);

    if (vehicleTypeMatch != null) {
      String extractedType = vehicleTypeMatch.group(1)!;
      vehicleType =
          vehicleTypeTranslations[extractedType] ?? extractedType.toLowerCase();
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
    );
  }

  static String _extractField(String response, String fieldName) {
    final match = RegExp(
      '"$fieldName":\\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(response);
    return match?.group(1) ?? 'NAN';
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
    };
  }

  factory VehicleDetail.fromJson(Map<String, dynamic> json) {
    return VehicleDetail(
      vehicleNumber: json['vehicle_number'] ?? 'NAN',
      chassisNumber: json['chassis_number'] ?? 'NAN',
      year: json['year'] ?? 'NAN',
      make: json['make'] ?? 'NAN',
      ownerNameEnglish: json['owner_name_english'] ?? 'NAN',
      ownerNameArabic: json['owner_name_arabic'] ?? 'NAN',
      ownerId: json['owner_id'] ?? 'NAN',
      vehicleType: json['vehicle_type'] ?? 'NAN',
      expiryDate: json['expiry_date'] ?? 'NAN',
    );
  }
}
