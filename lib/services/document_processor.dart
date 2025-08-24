//lib/services/document_processor.dart =====
import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/app_settings.dart';
import '../models/vehicle_detail.dart';
import 'platform_service.dart'; // NEW import

class DocumentProcessor {
  final _settings = AppSettings.instance;
  final _platformService = PlatformService.instance; // NEW

  Future<String> performOCR(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final response = await http.post(
      Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=${_settings.googleVisionApiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "requests": [
          {
            "image": {"content": base64Encode(bytes)},
            "features": [
              {"type": "TEXT_DETECTION"},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OCR failed: ${response.body}');
    }

    final ocrResult = jsonDecode(response.body);
    return ocrResult['responses'][0]['fullTextAnnotation']['text'] ??
        "No text found in the image.";
  }

  Future<VehicleDetail> processWithAI(String extractedText) async {
    final prompt = _generatePrompt();

    final chatResponse = await OpenAI.instance.chat.create(
      model: _settings.aiModel,
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              extractedText,
            ),
          ],
        ),
      ],
      maxTokens: _settings.maxTokens,
      temperature: 0.1,
    );

    final response = chatResponse.choices.first.message.content.toString();

    var vehicleDetail = VehicleDetail.fromApiResponse(
      response,
      _settings.vehicleTypeTranslations,
    );

    // Get platform expiry date if available
    final platformExpiry = _platformService.getPlatformExpiry(
      vehicleDetail.vehicleNumber,
    );

    if (platformExpiry != null) {
      vehicleDetail = vehicleDetail.copyWithPlatformExpiry(platformExpiry);
    }

    return vehicleDetail;
  }

  String _generatePrompt() {
    return '''
Extract vehicle registration information from this ${_settings.countryName} document.

Return JSON format:
{
  "vehicle_number": "string or 'NAN'",
  "chassis_number": "string or 'NAN'",
  "year": "string or 'NAN'",
  "make": "string or 'NAN'",
  "owner_name_english": "string or 'NAN'",
  "owner_name_arabic": "string or 'NAN'",
  "owner_id": "string or 'NAN'",
  "vehicle_type": "tipper or trailer or 'NAN'",
  "expiry_date": "YYYY-MM-DD or 'NAN'"
}

Rules:
1. Use 'NAN' for missing information
2. Dates must be YYYY-MM-DD format
3. Fix OCR errors (2015→2025 for expiry dates)
4. Vehicle type should only be "tipper" or "trailer"
5. Look for keywords: tipper, نشال, قلاب = "tipper"
6. Look for keywords: trailer, تريلا, رأس = "trailer"
''';
  }

  Future<void> saveToGoogleSheets(VehicleDetail detail) async {
    if (_settings.googleSheetsScriptUrl.isEmpty) {
      return;
    }

    // Build URL with platform expiry
    final url = Uri.parse(
      '${_settings.googleSheetsScriptUrl}?action=add'
      '&plate=${Uri.encodeComponent(detail.vehicleNumber)}'
      '&ownerA=${Uri.encodeComponent(detail.ownerNameArabic)}'
      '&ownerE=${Uri.encodeComponent(detail.ownerNameEnglish)}'
      '&ownerID=${Uri.encodeComponent(detail.ownerId)}'
      '&chassis=${Uri.encodeComponent(detail.chassisNumber)}'
      '&year=${Uri.encodeComponent(detail.year)}'
      '&make=${Uri.encodeComponent(detail.make)}'
      '&type=${Uri.encodeComponent(detail.vehicleType)}'
      '&expiry=${Uri.encodeComponent(detail.expiryDate)}'
      '&platformExpiry=${Uri.encodeComponent(detail.platformExpiryDate ?? "")}', // NEW
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to save to Google Sheets: ${response.body}');
    }
  }
}
