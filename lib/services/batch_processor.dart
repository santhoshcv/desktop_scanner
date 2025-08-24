//lib/services/batch_processor.dart (ENHANCED)

import 'dart:io';
import '../models/vehicle_detail.dart';
import '../models/batch_process_result.dart';
import 'document_processor.dart';

class BatchProcessor {
  final DocumentProcessor _documentProcessor = DocumentProcessor();

  Future<BatchProcessResult> processFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    try {
      final extractedText = await _documentProcessor.performOCR(file);
      final vehicleDetail = await _documentProcessor.processWithAI(
        extractedText,
      );

      return BatchProcessResult(
        fileName: fileName,
        vehicleDetail: vehicleDetail,
        error: null,
        processedAt: DateTime.now(),
      );
    } catch (e) {
      return BatchProcessResult(
        fileName: fileName,
        vehicleDetail: null,
        error: e.toString(),
        processedAt: DateTime.now(),
      );
    }
  }

  /// Enhanced method with progress callback and error handling
  Future<GoogleSheetsUploadResult> saveAllToGoogleSheets(
    List<VehicleDetail> details, {
    Function(int current, int total, String currentRecord)? onProgress,
  }) async {
    final result = GoogleSheetsUploadResult();

    for (int i = 0; i < details.length; i++) {
      final detail = details[i];

      // Update progress
      onProgress?.call(i + 1, details.length, detail.vehicleNumber);

      try {
        await _documentProcessor.saveToGoogleSheets(detail);
        result.successCount++;

        // Small delay to prevent API rate limiting
        if (i < details.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        result.failedRecords.add(
          GoogleSheetsUploadError(
            vehicleNumber: detail.vehicleNumber,
            error: e.toString(),
          ),
        );
      }
    }

    return result;
  }
}

/// Result class for Google Sheets upload operations
class GoogleSheetsUploadResult {
  int successCount = 0;
  List<GoogleSheetsUploadError> failedRecords = [];

  int get totalProcessed => successCount + failedRecords.length;
  bool get hasErrors => failedRecords.isNotEmpty;
  double get successRate =>
      totalProcessed > 0 ? successCount / totalProcessed : 0.0;
}

/// Error information for failed uploads
class GoogleSheetsUploadError {
  final String vehicleNumber;
  final String error;

  GoogleSheetsUploadError({required this.vehicleNumber, required this.error});
}
