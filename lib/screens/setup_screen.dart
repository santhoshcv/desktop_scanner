// lib/screens/setup_screen.dart =====
import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import '../config/app_settings.dart';
import '../services/platform_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _openAiController = TextEditingController();
  final _visionController = TextEditingController();
  final _sheetsController = TextEditingController();
  final _platformApiController = TextEditingController(); // NEW

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(48),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 80,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Document Scanner Pro',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _openAiController,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API Key',
                      hintText: 'sk-...',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'OpenAI API Key is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _visionController,
                    decoration: const InputDecoration(
                      labelText: 'Google Vision API Key',
                      hintText: 'AIza...',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Google Vision API Key is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _sheetsController,
                    decoration: const InputDecoration(
                      labelText: 'Google Sheets Script URL (Optional)',
                      hintText: 'https://script.google.com/macros/s/.../exec',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NEW: Platform API field
                  TextFormField(
                    controller: _platformApiController,
                    decoration: const InputDecoration(
                      labelText: 'Platform API URL (Optional)',
                      hintText: 'https://api.example.com/vehicles',
                      border: OutlineInputBorder(),
                      helperText: 'API endpoint to fetch vehicle platform data',
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _setupApp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Complete Setup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setupApp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final settings = AppSettings.instance;

      settings.openAiApiKey = _openAiController.text;
      settings.googleVisionApiKey = _visionController.text;
      settings.googleSheetsScriptUrl = _sheetsController.text;
      settings.platformApiUrl = _platformApiController.text; // NEW

      await settings.saveSettings();

      OpenAI.apiKey = settings.openAiApiKey;

      // Load platform vehicles if configured
      if (settings.platformApiUrl.isNotEmpty) {
        await PlatformService.instance.loadVehicles();
      }

      Navigator.pushReplacementNamed(context, '/main');
    }
  }
}
