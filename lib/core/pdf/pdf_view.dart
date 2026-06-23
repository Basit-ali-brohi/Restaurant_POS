import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';

/// In-app PDF preview with built-in Print and Download/Share actions.
/// Backed by the `printing` package's [PdfPreview] (renders the real document
/// and exposes a print dialog + share/save on desktop).
class PdfViewer {
  PdfViewer._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String fileName,
    required Future<Uint8List> Function(PdfPageFormat format) build,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 860),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 10, 14),
                  decoration: const BoxDecoration(color: AppColors.accent),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Preview with built-in print + share toolbar.
                Expanded(
                  child: PdfPreview(
                    build: build,
                    pdfFileName: fileName,
                    allowPrinting: true,
                    allowSharing: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    useActions: true,
                    scrollViewDecoration:
                        const BoxDecoration(color: Color(0xFFEDEDF2)),
                    actionBarTheme: const PdfActionBarTheme(
                      backgroundColor: Color(0xFFF4F4FA),
                      iconColor: AppColors.accent,
                    ),
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
