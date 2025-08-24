//lib/services/document_processor.dart

import 'dart:convert';
import 'dart:io';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../config/app_settings.dart';
import '../models/vehicle_detail.dart';

class DocumentProcessor {
  final _settings = AppSettings.instance;

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

    return VehicleDetail.fromApiResponse(
      response,
      _settings.vehicleTypeTranslations,
    );
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
  "vehicle_type": "string or 'NAN'",
  "expiry_date": "YYYY-MM-DD or 'NAN'"
}

Rules:
1. Use 'NAN' for missing information
2. Dates must be YYYY-MM-DD format
3. Fix OCR errors (2015→2025 for expiry dates)
''';
  }

  Future<void> saveToGoogleSheets(VehicleDetail detail) async {
    if (_settings.googleSheetsScriptUrl.isEmpty) {
      return;
    }

    final url = Uri.parse(
      '${_settings.googleSheetsScriptUrl}?action=add'
      '&plate=${detail.vehicleNumber}'
      '&ownerA=${detail.ownerNameArabic}'
      '&ownerE=${detail.ownerNameEnglish}'
      '&id=${detail.ownerId}'
      '&chassis=${detail.chassisNumber}'
      '&year=${detail.year}'
      '&make=${detail.make}'
      '&type=${detail.vehicleType}'
      '&expiry=${detail.expiryDate}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to save to Google Sheets');
    }
  }
}
