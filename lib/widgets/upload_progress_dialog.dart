//lib/widgets/upload_progress_dialog.dart

import 'package:flutter/material.dart';
import '../services/batch_processor.dart';

// Controller to manage progress updates
class UploadProgressController extends ChangeNotifier {
  int _currentRecord = 0;
  String _currentVehicleNumber = '';
  bool _isCompleted = false;
  GoogleSheetsUploadResult? _result;

  int get currentRecord => _currentRecord;
  String get currentVehicleNumber => _currentVehicleNumber;
  bool get isCompleted => _isCompleted;
  GoogleSheetsUploadResult? get result => _result;

  void updateProgress(int current, String vehicleNumber) {
    _currentRecord = current;
    _currentVehicleNumber = vehicleNumber;
    notifyListeners();
  }

  void setCompleted(GoogleSheetsUploadResult result) {
    _isCompleted = true;
    _result = result;
    notifyListeners();
  }

  void reset() {
    _currentRecord = 0;
    _currentVehicleNumber = '';
    _isCompleted = false;
    _result = null;
  }
}

class UploadProgressDialog extends StatefulWidget {
  final int totalRecords;
  final UploadProgressController controller;

  const UploadProgressDialog({
    Key? key,
    required this.totalRecords,
    required this.controller,
  }) : super(key: key);

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onProgressUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.totalRecords > 0
            ? widget.controller.currentRecord / widget.totalRecords
            : 0.0;

    return WillPopScope(
      onWillPop: () async => widget.controller.isCompleted,
      child: Dialog(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.controller.isCompleted
                        ? (widget.controller.result?.hasErrors ?? false
                            ? Icons.warning
                            : Icons.cloud_done)
                        : Icons.cloud_upload,
                    size: 32,
                    color:
                        widget.controller.isCompleted
                            ? (widget.controller.result?.hasErrors ?? false
                                ? Colors.orange
                                : Colors.green)
                            : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.controller.isCompleted
                          ? 'Upload Complete'
                          : 'Uploading to Google Sheets',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.controller.isCompleted)
                    IconButton(
                      onPressed:
                          () => Navigator.of(
                            context,
                          ).pop(widget.controller.result),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              if (!widget.controller.isCompleted) ...[
                // Progress indicator
                SizedBox(
                  width: double.infinity,
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),

                // Progress text
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Uploading record ${widget.controller.currentRecord} of ${widget.totalRecords}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),

                if (widget.controller.currentVehicleNumber.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Vehicle: ${widget.controller.currentVehicleNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                const Text(
                  'Please wait while records are being uploaded...',
                  style: TextStyle(color: Colors.grey),
                ),
              ] else ...[
                // Completion summary
                _buildCompletionSummary(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionSummary() {
    final result = widget.controller.result!;

    return Column(
      children: [
        // Success/Error summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: result.hasErrors ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  result.hasErrors ? Colors.orange[200]! : Colors.green[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Successful',
                    result.successCount.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatItem(
                    'Failed',
                    result.failedRecords.length.toString(),
                    Colors.red,
                    Icons.error,
                  ),
                  _buildStatItem(
                    'Total',
                    result.totalProcessed.toString(),
                    Colors.blue,
                    Icons.list,
                  ),
                ],
              ),
              if (result.hasErrors) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Success Rate: ${(result.successRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ],
          ),
        ),

        if (result.hasErrors) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text(
              'Failed Records (${result.failedRecords.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.error_outline, color: Colors.red),
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.failedRecords.length,
                  itemBuilder: (context, index) {
                    final error = result.failedRecords[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 20,
                      ),
                      title: Text(error.vehicleNumber),
                      subtitle: Text(
                        error.error,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(widget.controller.result),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
