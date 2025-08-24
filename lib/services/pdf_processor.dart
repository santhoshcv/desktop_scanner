//lib/services/pdf_processor.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';
import 'package:path/path.dart' as path;
import '../models/vehicle_detail.dart';
import '../models/batch_process_result.dart';
import 'document_processor.dart';

class PdfProcessor {
  final DocumentProcessor _documentProcessor = DocumentProcessor();

  /// Get total number of pages in a PDF
  Future<int> getPdfPageCount(File pdfFile) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;
      await document.close();
      return pageCount;
    } catch (e) {
      throw Exception('Failed to read PDF: $e');
    }
  }

  /// Process PDF pages within specified range
  Future<List<BatchProcessResult>> processPdfPages(
    File pdfFile,
    int startPage,
    int endPage, {
    Function(int currentPage, int totalPages)? onProgress,
  }) async {
    List<BatchProcessResult> results = [];
    PdfDocument? document;

    try {
      document = await PdfDocument.openFile(pdfFile.path);

      // Validate page range
      final totalPages = document.pagesCount;
      if (startPage < 1 || endPage > totalPages || startPage > endPage) {
        throw Exception(
          'Invalid page range: $startPage-$endPage (Total: $totalPages)',
        );
      }

      final fileName = path.basenameWithoutExtension(pdfFile.path);

      for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
        try {
          onProgress?.call(pageNum - startPage + 1, endPage - startPage + 1);

          // Convert PDF page to image
          final imageBytes = await _convertPdfPageToImage(document, pageNum);

          // Create temporary image file
          final tempDir = Directory.systemTemp;
          final tempImageFile = File(
            '${tempDir.path}/page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempImageFile.writeAsBytes(imageBytes);

          try {
            // Process the image
            final extractedText = await _documentProcessor.performOCR(
              tempImageFile,
            );
            final vehicleDetail = await _documentProcessor.processWithAI(
              extractedText,
            );

            results.add(
              BatchProcessResult(
                fileName: '${fileName}_page_$pageNum',
                vehicleDetail: vehicleDetail,
                error: null,
                processedAt: DateTime.now(),
              ),
            );
          } catch (e) {
            results.add(
              BatchProcessResult(
                fileName: '${fileName}_page_$pageNum',
                vehicleDetail: null,
                error: 'Page $pageNum: $e',
                processedAt: DateTime.now(),
              ),
            );
          } finally {
            // Clean up temporary file
            if (await tempImageFile.exists()) {
              await tempImageFile.delete();
            }
          }
        } catch (e) {
          results.add(
            BatchProcessResult(
              fileName: '${fileName}_page_$pageNum',
              vehicleDetail: null,
              error: 'Failed to process page $pageNum: $e',
              processedAt: DateTime.now(),
            ),
          );
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    } finally {
      // Always close the document
      if (document != null) {
        await document.close();
      }
    }
  }

  /// Convert a single PDF page to PNG image bytes
  Future<Uint8List> _convertPdfPageToImage(
    PdfDocument document,
    int pageNumber,
  ) async {
    try {
      // Get the page (pageNumber is 1-based)
      final page = await document.getPage(pageNumber);

      // Render page as image with high DPI for better OCR accuracy
      final pageImage = await page.render(
        width: page.width * 2, // 2x scale for better quality
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      // Close the page
      await page.close();

      return pageImage!.bytes;
    } catch (e) {
      throw Exception('Failed to convert PDF page to image: $e');
    }
  }

  /// Process specific pages based on user selection
  Future<List<BatchProcessResult>> processSelectedPages(
    File pdfFile,
    List<int> selectedPages, {
    Function(int currentPage, int totalPages)? onProgress,
  }) async {
    List<BatchProcessResult> results = [];

    try {
      final bytes = await pdfFile.readAsBytes();
      final document = await PdfDocument.openData(bytes);
      final totalPages = document.pagesCount;

      // Validate selected pages
      for (int pageNum in selectedPages) {
        if (pageNum < 1 || pageNum > totalPages) {
          throw Exception('Invalid page number: $pageNum (Total: $totalPages)');
        }
      }

      final fileName = path.basenameWithoutExtension(pdfFile.path);

      for (int i = 0; i < selectedPages.length; i++) {
        final pageNum = selectedPages[i];

        try {
          onProgress?.call(i + 1, selectedPages.length);

          // Convert PDF page to image
          final imageBytes = await _convertPdfPageToImage(
            document,
            pageNum - 1,
          );

          // Create temporary image file
          final tempDir = Directory.systemTemp;
          final tempImageFile = File(
            '${tempDir.path}/page_${pageNum}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await tempImageFile.writeAsBytes(imageBytes);

          try {
            // Process the image
            final extractedText = await _documentProcessor.performOCR(
              tempImageFile,
            );
            final vehicleDetail = await _documentProcessor.processWithAI(
              extractedText,
            );

            results.add(
              BatchProcessResult(
                fileName: '${fileName}_page_$pageNum',
                vehicleDetail: vehicleDetail,
                error: null,
                processedAt: DateTime.now(),
              ),
            );
          } catch (e) {
            results.add(
              BatchProcessResult(
                fileName: '${fileName}_page_$pageNum',
                vehicleDetail: null,
                error: 'Page $pageNum: $e',
                processedAt: DateTime.now(),
              ),
            );
          } finally {
            // Clean up temporary file
            if (await tempImageFile.exists()) {
              await tempImageFile.delete();
            }
          }
        } catch (e) {
          results.add(
            BatchProcessResult(
              fileName: '${fileName}_page_$pageNum',
              vehicleDetail: null,
              error: 'Failed to process page $pageNum: $e',
              processedAt: DateTime.now(),
            ),
          );
        }
      }

      await document.close();
      return results;
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
  }
}
