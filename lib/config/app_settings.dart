// lib/config/app_settings.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static AppSettings? _instance;
  static AppSettings get instance => _instance ??= AppSettings._();
  AppSettings._();

  // API Configuration
  String openAiApiKey = '';
  String googleVisionApiKey = '';
  String googleSheetsScriptUrl = '';

  // Regional Settings
  String countryCode = 'QA';
  String countryName = 'Qatar';

  // Processing Settings
  int maxTokens = 300;
  String aiModel = 'gpt-4';

  // Vehicle Type Translations
  Map<String, String> vehicleTypeTranslations = {
    'نشال': 'tipper',
    'قلاب': 'tipper',
    'Tipper': 'tipper',
    'رأس تريلا': 'trailer',
    'Trailer': 'trailer',
    'مقطوره قلاب': 'tail',
    'مقطوره نشال': 'tail',
  };

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    openAiApiKey = prefs.getString('openai_api_key') ?? '';
    googleVisionApiKey = prefs.getString('google_vision_api_key') ?? '';
    googleSheetsScriptUrl = prefs.getString('google_sheets_script_url') ?? '';
    countryCode = prefs.getString('country_code') ?? 'QA';
    countryName = prefs.getString('country_name') ?? 'Qatar';
    maxTokens = prefs.getInt('max_tokens') ?? 300;
    aiModel = prefs.getString('ai_model') ?? 'gpt-4';
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('openai_api_key', openAiApiKey);
    await prefs.setString('google_vision_api_key', googleVisionApiKey);
    await prefs.setString('google_sheets_script_url', googleSheetsScriptUrl);
    await prefs.setString('country_code', countryCode);
    await prefs.setString('country_name', countryName);
    await prefs.setInt('max_tokens', maxTokens);
    await prefs.setString('ai_model', aiModel);
  }

  bool get isConfigured {
    return openAiApiKey.isNotEmpty && googleVisionApiKey.isNotEmpty;
  }
}
