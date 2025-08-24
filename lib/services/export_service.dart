//lib/services/export_service.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/vehicle_detail.dart';

class ExportService {
  Future<void> exportToCsv(
    List<VehicleDetail> vehicles,
    String filePath,
  ) async {
    List<List<dynamic>> rows = [];

    rows.add([
      'Vehicle Number',
      'Chassis Number',
      'Year',
      'Make',
      'Owner Name (English)',
      'Owner Name (Arabic)',
      'Owner ID',
      'Vehicle Type',
      'Expiry Date',
    ]);

    for (var vehicle in vehicles) {
      rows.add([
        vehicle.vehicleNumber,
        vehicle.chassisNumber,
        vehicle.year,
        vehicle.make,
        vehicle.ownerNameEnglish,
        vehicle.ownerNameArabic,
        vehicle.ownerId,
        vehicle.vehicleType,
        vehicle.expiryDate,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final file = File(filePath);
    await file.writeAsString(csvData);
  }

  Future<void> exportToExcel(
    List<VehicleDetail> vehicles,
    String filePath,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Vehicle Data'];

    sheet.appendRow([
      TextCellValue('Vehicle Number'),
      TextCellValue('Chassis Number'),
      TextCellValue('Year'),
      TextCellValue('Make'),
      TextCellValue('Owner Name (English)'),
      TextCellValue('Owner Name (Arabic)'),
      TextCellValue('Owner ID'),
      TextCellValue('Vehicle Type'),
      TextCellValue('Expiry Date'),
    ]);

    for (var vehicle in vehicles) {
      sheet.appendRow([
        TextCellValue(vehicle.vehicleNumber),
        TextCellValue(vehicle.chassisNumber),
        TextCellValue(vehicle.year),
        TextCellValue(vehicle.make),
        TextCellValue(vehicle.ownerNameEnglish),
        TextCellValue(vehicle.ownerNameArabic),
        TextCellValue(vehicle.ownerId),
        TextCellValue(vehicle.vehicleType),
        TextCellValue(vehicle.expiryDate),
      ]);
    }

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
  }
}
