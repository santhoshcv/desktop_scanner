//lib/widgets/pdf_page_selector_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pdf_processor.dart';

class PdfPageSelectorDialog extends StatefulWidget {
  final File pdfFile;

  const PdfPageSelectorDialog({Key? key, required this.pdfFile})
    : super(key: key);

  @override
  State<PdfPageSelectorDialog> createState() => _PdfPageSelectorDialogState();
}

class _PdfPageSelectorDialogState extends State<PdfPageSelectorDialog> {
  final PdfProcessor _pdfProcessor = PdfProcessor();
  final TextEditingController _startPageController = TextEditingController(
    text: '1',
  );
  final TextEditingController _endPageController = TextEditingController();

  int? _totalPages;
  bool _isLoadingPageCount = true;
  String? _error;
  ProcessingMode _processingMode = ProcessingMode.range;

  @override
  void initState() {
    super.initState();
    _loadPageCount();
  }

  Future<void> _loadPageCount() async {
    try {
      final pageCount = await _pdfProcessor.getPdfPageCount(widget.pdfFile);
      setState(() {
        _totalPages = pageCount;
        _endPageController.text = pageCount.toString();
        _isLoadingPageCount = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPageCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Process PDF: ${widget.pdfFile.path.split(Platform.pathSeparator).last}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoadingPageCount)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              )
            else
              _buildPageSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Total Pages: $_totalPages'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Processing Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        RadioListTile<ProcessingMode>(
          title: const Text('Process page range'),
          subtitle: const Text('Select start and end page numbers'),
          value: ProcessingMode.range,
          groupValue: _processingMode,
          onChanged: (value) {
            setState(() {
              _processingMode = value!;
            });
          },
        ),

        RadioListTile<ProcessingMode>(
          title: const Text('Process all pages'),
          subtitle: const Text('Process entire PDF document'),
          value: ProcessingMode.all,
          groupValue: _processingMode,
          onChanged: (value) {
            setState(() {
              _processingMode = value!;
            });
          },
        ),

        if (_processingMode == ProcessingMode.range) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startPageController,
                  decoration: const InputDecoration(
                    labelText: 'Start Page',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _endPageController,
                  decoration: const InputDecoration(
                    labelText: 'End Page',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _canProcess() ? _onProcessPressed : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(_getProcessButtonText()),
            ),
          ],
        ),
      ],
    );
  }

  bool _canProcess() {
    if (_totalPages == null) return false;

    if (_processingMode == ProcessingMode.all) return true;

    final startPage = int.tryParse(_startPageController.text);
    final endPage = int.tryParse(_endPageController.text);

    if (startPage == null || endPage == null) return false;
    if (startPage < 1 || endPage > _totalPages!) return false;
    if (startPage > endPage) return false;

    return true;
  }

  String _getProcessButtonText() {
    if (_processingMode == ProcessingMode.all) {
      return 'Process All $_totalPages Pages';
    } else {
      final startPage = int.tryParse(_startPageController.text) ?? 0;
      final endPage = int.tryParse(_endPageController.text) ?? 0;
      final pageCount = endPage - startPage + 1;
      return 'Process $pageCount Pages';
    }
  }

  void _onProcessPressed() {
    final PdfProcessingConfig config;

    if (_processingMode == ProcessingMode.all) {
      config = PdfProcessingConfig(
        pdfFile: widget.pdfFile,
        startPage: 1,
        endPage: _totalPages!,
        totalPages: _totalPages!,
      );
    } else {
      final startPage = int.parse(_startPageController.text);
      final endPage = int.parse(_endPageController.text);
      config = PdfProcessingConfig(
        pdfFile: widget.pdfFile,
        startPage: startPage,
        endPage: endPage,
        totalPages: _totalPages!,
      );
    }

    Navigator.of(context).pop(config);
  }
}

enum ProcessingMode { range, all }

class PdfProcessingConfig {
  final File pdfFile;
  final int startPage;
  final int endPage;
  final int totalPages;

  PdfProcessingConfig({
    required this.pdfFile,
    required this.startPage,
    required this.endPage,
    required this.totalPages,
  });

  int get pageCount => endPage - startPage + 1;
}
