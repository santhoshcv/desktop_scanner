//lib/models/batch_process_result.dart

import 'vehicle_detail.dart';

class BatchProcessResult {
  final String fileName;
  final VehicleDetail? vehicleDetail;
  final String? error;
  final DateTime processedAt;

  BatchProcessResult({
    required this.fileName,
    this.vehicleDetail,
    this.error,
    required this.processedAt,
  });

  bool get isSuccess => vehicleDetail != null && error == null;
}
