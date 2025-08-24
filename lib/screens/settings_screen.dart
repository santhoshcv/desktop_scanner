// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../config/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings.instance;
  late TextEditingController _openAiController;
  late TextEditingController _visionController;
  late TextEditingController _sheetsController;

  @override
  void initState() {
    super.initState();
    _openAiController = TextEditingController(text: _settings.openAiApiKey);
    _visionController = TextEditingController(
      text: _settings.googleVisionApiKey,
    );
    _sheetsController = TextEditingController(
      text: _settings.googleSheetsScriptUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'API Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _openAiController,
                decoration: const InputDecoration(
                  labelText: 'OpenAI API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _visionController,
                decoration: const InputDecoration(
                  labelText: 'Google Vision API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sheetsController,
                decoration: const InputDecoration(
                  labelText: 'Google Sheets Script URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSettings() async {
    _settings.openAiApiKey = _openAiController.text;
    _settings.googleVisionApiKey = _visionController.text;
    _settings.googleSheetsScriptUrl = _sheetsController.text;

    await _settings.saveSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }
}
