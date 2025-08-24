//lib/screens/main_desktop_screen.dart

import 'package:desktop_scanner/services/pdf_processor.dart';
import 'package:desktop_scanner/widgets/pdf_page_selector_dialog.dart';
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
  final PdfProcessor _pdfProcessor = PdfProcessor();
  final ExportService _exportService = ExportService();

  List<File> _selectedFiles = [];
  File? _selectedPdfFile;
  List<BatchProcessResult> _results = [];
  bool _isProcessing = false;
  double _processingProgress = 0.0;
  String _currentProcessingFile = '';
  String? _selectedFolderPath;
  ProcessingType _currentProcessingType = ProcessingType.none;

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
              // PDF Processing Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.picture_as_pdf, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'PDF Processing',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _selectPdfFile,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Select PDF'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Image Processing Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.image, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Image Processing',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _selectFolder,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Select Folder'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _selectFiles,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Select Files'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        Expanded(child: _buildFilesList()),

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

  Widget _buildFilesList() {
    if (_selectedPdfFile != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected PDF:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.red[50],
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(
                  _selectedPdfFile!.path.split(Platform.pathSeparator).last,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed:
                      _isProcessing
                          ? null
                          : () {
                            setState(() {
                              _selectedPdfFile = null;
                              _currentProcessingType = ProcessingType.none;
                            });
                          },
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedFiles.isEmpty) {
      return const Center(child: Text('No files selected'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedFiles.length,
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        final fileName = file.path.split(Platform.pathSeparator).last;
        return Card(
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.image, size: 20),
            title: Text(fileName, style: const TextStyle(fontSize: 13)),
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
    );
  }

  Widget _buildHeader() {
    String headerText;
    String subtitleText;

    if (_selectedPdfFile != null) {
      headerText =
          'PDF: ${_selectedPdfFile!.path.split(Platform.pathSeparator).last}';
      subtitleText = 'PDF processing | ${_results.length} processed';
    } else if (_selectedFolderPath != null) {
      headerText =
          'Folder: ${_selectedFolderPath!.split(Platform.pathSeparator).last}';
      subtitleText =
          '${_selectedFiles.length} files | ${_results.length} processed';
    } else {
      headerText = 'No files selected';
      subtitleText = 'Select PDF or images to process';
    }

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
                headerText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitleText,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          if (_canStartProcessing() && !_isProcessing)
            ElevatedButton.icon(
              onPressed: _startProcessing,
              icon: const Icon(Icons.play_arrow),
              label: Text(_getProcessButtonText()),
            ),
        ],
      ),
    );
  }

  Future<void> _selectPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.first.path != null) {
      final pdfFile = File(result.files.first.path!);

      // Show PDF page selector dialog
      final config = await showDialog<PdfProcessingConfig>(
        context: context,
        builder: (context) => PdfPageSelectorDialog(pdfFile: pdfFile),
      );

      if (config != null) {
        setState(() {
          _selectedPdfFile = pdfFile;
          _selectedFiles.clear();
          _selectedFolderPath = null;
          _results.clear();
          _currentProcessingType = ProcessingType.pdf;
        });
      }
    }
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
          Text(_getProcessingSubtitle()),
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
        _selectedPdfFile = null;
        _results.clear();
        _currentProcessingType = ProcessingType.images;
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
        _selectedPdfFile = null;
        _selectedFolderPath = null;
        _results.clear();
        _currentProcessingType = ProcessingType.images;
      });
    }
  }

  bool _canStartProcessing() {
    return (_selectedFiles.isNotEmpty || _selectedPdfFile != null);
  }

  String _getProcessButtonText() {
    if (_selectedPdfFile != null) {
      return 'Process PDF';
    } else {
      return 'Process ${_selectedFiles.length} Files';
    }
  }

  String _getProcessingSubtitle() {
    if (_currentProcessingType == ProcessingType.pdf) {
      return 'Processing PDF pages';
    } else {
      final totalFiles = _selectedFiles.length;
      final currentFile = (_processingProgress * totalFiles).round();
      return '$currentFile of $totalFiles files';
    }
  }

  Future<void> _startProcessing() async {
    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
      _results.clear();
    });

    if (_selectedPdfFile != null) {
      await _processPdf();
    } else {
      await _processImages();
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _processPdf() async {
    // Show PDF page selector dialog again to get processing config
    final config = await showDialog<PdfProcessingConfig>(
      context: context,
      builder: (context) => PdfPageSelectorDialog(pdfFile: _selectedPdfFile!),
    );

    if (config == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      final results = await _pdfProcessor.processPdfPages(
        config.pdfFile,
        config.startPage,
        config.endPage,
        onProgress: (current, total) {
          setState(() {
            _processingProgress = current / total;
            _currentProcessingFile = 'Page $current of $total';
          });
        },
      );

      setState(() {
        _results.addAll(results);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing PDF: $e')));
    }
  }

  Future<void> _processImages() async {
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

enum ProcessingType { none, images, pdf }
