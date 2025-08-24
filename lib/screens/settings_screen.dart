//lib/screens/settings_screen.dart =====
import 'package:flutter/material.dart';
import '../config/app_settings.dart';
import '../services/platform_service.dart';

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
  late TextEditingController _platformApiController; // NEW
  bool _isTestingPlatformApi = false; // NEW

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
    _platformApiController = TextEditingController(
      text: _settings.platformApiUrl,
    ); // NEW
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
          child: SingleChildScrollView(
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
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _visionController,
                  decoration: const InputDecoration(
                    labelText: 'Google Vision API Key',
                    hintText: 'AIza...',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _sheetsController,
                  decoration: const InputDecoration(
                    labelText: 'Google Sheets Script URL',
                    hintText: 'https://script.google.com/macros/s/.../exec',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // NEW: Platform API field
                TextField(
                  controller: _platformApiController,
                  decoration: InputDecoration(
                    labelText: 'Platform API URL',
                    hintText: 'https://api.example.com/vehicles',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon:
                          _isTestingPlatformApi
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.refresh),
                      onPressed:
                          _isTestingPlatformApi ? null : _testPlatformApi,
                      tooltip: 'Test API Connection',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Platform API status
                if (PlatformService.instance.isLoaded)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          PlatformService.instance.vehicles.isNotEmpty
                              ? Colors.green[50]
                              : Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color:
                            PlatformService.instance.vehicles.isNotEmpty
                                ? Colors.green[200]!
                                : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          PlatformService.instance.vehicles.isNotEmpty
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color:
                              PlatformService.instance.vehicles.isNotEmpty
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          PlatformService.instance.vehicles.isNotEmpty
                              ? '${PlatformService.instance.vehicles.length} vehicles loaded'
                              : 'No vehicles loaded',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                PlatformService.instance.vehicles.isNotEmpty
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                          ),
                        ),
                      ],
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
      ),
    );
  }

  Future<void> _testPlatformApi() async {
    setState(() {
      _isTestingPlatformApi = true;
    });

    try {
      _settings.platformApiUrl = _platformApiController.text;
      await PlatformService.instance.reloadVehicles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully loaded ${PlatformService.instance.vehicles.length} vehicles',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load vehicles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingPlatformApi = false;
      });
    }
  }

  void _saveSettings() async {
    _settings.openAiApiKey = _openAiController.text;
    _settings.googleVisionApiKey = _visionController.text;
    _settings.googleSheetsScriptUrl = _sheetsController.text;
    _settings.platformApiUrl = _platformApiController.text; // NEW

    await _settings.saveSettings();

    // Reload platform vehicles if API URL changed
    if (_settings.platformApiUrl.isNotEmpty) {
      await PlatformService.instance.reloadVehicles();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }
}
