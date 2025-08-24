// ===== 2. NEW FILE: lib/models/platform_vehicle.dart =====
class PlatformVehicle {
  final int autoId;
  final String plateNumber;
  final String? expiryDate;
  final String? deviceId;
  final String? companyName;

  PlatformVehicle({
    required this.autoId,
    required this.plateNumber,
    this.expiryDate,
    this.deviceId,
    this.companyName,
  });

  factory PlatformVehicle.fromJson(Map<String, dynamic> json) {
    return PlatformVehicle(
      autoId: json['autoid'] ?? 0,
      plateNumber: (json['plate_number'] ?? json['title'] ?? '').toString(),
      expiryDate: json['expiry_date']?.toString(),
      deviceId: json['device_id']?.toString(),
      companyName: json['company_name']?.toString(),
    );
  }

  // Format expiry date to YYYY-MM-DD
  String? get formattedExpiryDate {
    if (expiryDate == null) return null;

    try {
      // Parse ISO date and return in YYYY-MM-DD format
      final date = DateTime.parse(expiryDate!);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return expiryDate; // Return as-is if parsing fails
    }
  }
}
