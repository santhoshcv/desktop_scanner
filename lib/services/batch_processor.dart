//lib/services/batch_processor.dart

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

  Future<void> saveAllToGoogleSheets(List<VehicleDetail> details) async {
    for (final detail in details) {
      await _documentProcessor.saveToGoogleSheets(detail);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
