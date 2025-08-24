//lib/screens/main_desktop_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:data_table_2/data_table_2.dart';
import 'dart:io';
import '../services/batch_processor.dart';
import '../models/vehicle_detail.dart';
import '../models/batch_process_result.dart';
import '../services/export_service.dart';

class MainDesktopScreen extends StatefulWidget {
  const MainDesktopScreen({Key? key}) : super(key: key);

  @override
  State<MainDesktopScreen> createState() => _MainDesktopScreenState();
}

class _MainDesktopScreenState extends State<MainDesktopScreen> {
  final BatchProcessor _batchProcessor = BatchProcessor();
  final ExportService _exportService = ExportService();

  List<File> _selectedFiles = [];
  List<BatchProcessResult> _results = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String _currentProcessingFile = '';
  String? _selectedFolderPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 300,
            color: Colors.grey[100],
            child: _buildSidebar(),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child:
                      _isProcessing
                          ? _buildProcessingView()
                          : _results.isEmpty
                          ? _buildEmptyState()
                          : _buildResultsView(),
                ),
                if (_results.isNotEmpty && !_isProcessing)
                  _buildFooterActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.purple[700],
          child: Row(
            children: [
              const Icon(Icons.document_scanner, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Scanner Pro',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Desktop Edition',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _selectFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Select Folder'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _selectFiles,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Files'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        Expanded(
          child:
              _selectedFiles.isEmpty
                  ? const Center(child: Text('No files selected'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      final fileName =
                          file.path.split(Platform.pathSeparator).last;
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.image, size: 20),
                          title: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed:
                                _isProcessing
                                    ? null
                                    : () {
                                      setState(() {
                                        _selectedFiles.removeAt(index);
                                      });
                                    },
                          ),
                        ),
                      );
                    },
                  ),
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: const Icon(Icons.settings),
            label: const Text('Settings'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFolderPath != null
                    ? 'Folder: ${_selectedFolderPath!.split(Platform.pathSeparator).last}'
                    : 'No folder selected',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedFiles.length} files | ${_results.length} processed',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          if (_selectedFiles.isNotEmpty && !_isProcessing)
            ElevatedButton.icon(
              onPressed: _startProcessing,
              icon: const Icon(Icons.play_arrow),
              label: Text('Process ${_selectedFiles.length} Files'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 120, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'No documents to process',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text('Select a folder or files to begin'),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: _processingProgress,
              strokeWidth: 8,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${(_processingProgress * 100).toInt()}%',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text('Processing: $_currentProcessingFile'),
          Text(
            '${(_processingProgress * _selectedFiles.length).round()} of ${_selectedFiles.length} files',
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 1000,
            columns: const [
              DataColumn2(label: Text('File'), size: ColumnSize.L),
              DataColumn2(label: Text('Vehicle #'), size: ColumnSize.M),
              DataColumn2(label: Text('Owner'), size: ColumnSize.L),
              DataColumn2(label: Text('Type'), size: ColumnSize.S),
              DataColumn2(label: Text('Expiry'), size: ColumnSize.M),
              DataColumn2(label: Text('Status'), size: ColumnSize.S),
            ],
            rows:
                _results.map((result) {
                  final detail = result.vehicleDetail;
                  return DataRow2(
                    cells: [
                      DataCell(Text(result.fileName)),
                      DataCell(Text(detail?.vehicleNumber ?? 'ERROR')),
                      DataCell(Text(detail?.ownerNameEnglish ?? '-')),
                      DataCell(Text(detail?.vehicleType ?? '-')),
                      DataCell(Text(detail?.expiryDate ?? '-')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                result.isSuccess
                                    ? Colors.green[100]
                                    : Colors.red[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.isSuccess ? 'Success' : 'Failed',
                            style: TextStyle(
                              color:
                                  result.isSuccess ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _results.clear();
                _selectedFiles.clear();
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear All'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _exportResults('csv'),
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _saveToGoogleSheets,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Save to Sheets'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final directory = Directory(selectedDirectory);
      final files =
          directory
              .listSync()
              .where(
                (file) =>
                    file is File &&
                    [
                      '.jpg',
                      '.jpeg',
                      '.png',
                      '.bmp',
                    ].any((ext) => file.path.toLowerCase().endsWith(ext)),
              )
              .map((file) => file as File)
              .toList();

      setState(() {
        _selectedFolderPath = selectedDirectory;
        _selectedFiles = files;
        _results.clear();
      });
    }
  }

  Future<void> _selectFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths.map((path) => File(path!)).toList();
        _results.clear();
      });
    }
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
      _results.clear();
    });

    for (int i = 0; i < _selectedFiles.length; i++) {
      final file = _selectedFiles[i];

      setState(() {
        _currentProcessingFile = file.path.split(Platform.pathSeparator).last;
        _processingProgress = (i + 1) / _selectedFiles.length;
      });

      try {
        final result = await _batchProcessor.processFile(file);
        setState(() {
          _results.add(result);
        });
      } catch (e) {
        setState(() {
          _results.add(
            BatchProcessResult(
              fileName: _currentProcessingFile,
              vehicleDetail: null,
              error: e.toString(),
              processedAt: DateTime.now(),
            ),
          );
        });
      }
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _exportResults(String format) async {
    final successfulResults =
        _results
            .where((r) => r.vehicleDetail != null)
            .map((r) => r.vehicleDetail!)
            .toList();

    if (successfulResults.isEmpty) return;

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save export file',
      fileName: 'vehicle_data.${format}',
    );

    if (outputFile != null) {
      if (format == 'csv') {
        await _exportService.exportToCsv(successfulResults, outputFile);
      } else {
        await _exportService.exportToExcel(successfulResults, outputFile);
      }
    }
  }

  Future<void> _saveToGoogleSheets() async {
    final successfulResults =
        _results
            .where((r) => r.vehicleDetail != null)
            .map((r) => r.vehicleDetail!)
            .toList();

    if (successfulResults.isEmpty) return;

    await _batchProcessor.saveAllToGoogleSheets(successfulResults);
  }
}
