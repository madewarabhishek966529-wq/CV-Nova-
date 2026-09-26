import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExtractionException implements Exception {
  const PdfExtractionException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PdfExtractor {
  /// Extracts all plaintext content from the given PDF bytes.
  /// Throws [PdfExtractionException] if the file cannot be read or contains no text.
  static String extractText(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const PdfExtractionException('Uploaded file is empty.');
    }

    try {
      final document = PdfDocument(inputBytes: Uint8List.fromList(bytes));
      final text = PdfTextExtractor(document).extractText();
      document.dispose();

      final cleaned = text.trim();
      if (cleaned.isEmpty) {
        throw const PdfExtractionException(
          'No extractable text found — this may be a scanned image or non-text PDF.',
        );
      }

      return cleaned;
    } on PdfExtractionException {
      rethrow;
    } catch (e) {
      throw PdfExtractionException('Failed to read PDF: $e');
    }
  }
}
