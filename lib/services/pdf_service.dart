import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/asset_model.dart';

/// Service for generating PDF custody certificates
class PdfService {
  /// Generate asset custody certificate PDF
  static Future<Uint8List> generateCustodyCertificate({
    required AssetModel asset,
    required String employeeName,
    required String employeeId,
    required Uint8List? issuerSignature,
    required Uint8List? recipientSignature,
    String? notes,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (companyLogo != null)
                      pw.Image(
                        pw.MemoryImage(companyLogo),
                        width: 80,
                        height: 80,
                      )
                    else
                      pw.Container(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ASSET CUSTODY CERTIFICATE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Asset Information
                pw.Text(
                  'Asset Information',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildInfoRow('Asset Name:', asset.name),
                _buildInfoRow('Serial Number:', asset.serialNumber),
                _buildInfoRow('Category:', asset.category),
                _buildInfoRow('Status:', AssetModel.statusToString(asset.status)),

                pw.SizedBox(height: 20),

                // Employee Information
                pw.Text(
                  'Recipient Information',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildInfoRow('Employee Name:', employeeName),
                _buildInfoRow('Employee ID:', employeeId),

                pw.SizedBox(height: 20),

                // Notes
                if (notes != null && notes.isNotEmpty) ...[
                  pw.Text(
                    'Notes',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      notes,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Issuer Signature
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (issuerSignature != null)
                          pw.Container(
                            width: 180,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child: pw.Image(pw.MemoryImage(issuerSignature)),
                          )
                        else
                          pw.Container(
                            width: 180,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text('Issuer Signature',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),

                    // Recipient Signature
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (recipientSignature != null)
                          pw.Container(
                            width: 180,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                            child:
                                pw.Image(pw.MemoryImage(recipientSignature)),
                          )
                        else
                          pw.Container(
                            width: 180,
                            height: 80,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(),
                            ),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text('Recipient Signature',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated document. No signature is required.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate QR code label PDF for printing
  static Future<Uint8List> generateQrLabel({
    required String assetId,
    required String assetName,
    required String serialNumber,
    required Uint8List qrCodeImage,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          8 * PdfPageFormat.cm,
          5 * PdfPageFormat.cm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Image(
                  pw.MemoryImage(qrCodeImage),
                  width: 100,
                  height: 100,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  assetName,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'SN: $serialNumber',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
