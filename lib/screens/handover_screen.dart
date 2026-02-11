import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../services/handover_service.dart';
import '../services/pdf_service.dart';
import '../widgets/signature_pad_widget.dart';
import '../theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';

class HandoverScreen extends StatefulWidget {
  final AssetModel? preselectedAsset;

  const HandoverScreen({super.key, this.preselectedAsset});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final _recipientController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  AssetModel? _selectedAsset;
  final _employeeNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAsset = widget.preselectedAsset;
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _recipientController.dispose();
    _employeeNameController.dispose();
    _employeeIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitHandover() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAsset == null) {
      _showSnackBar('Please select an asset', isError: true);
      return;
    }

    if (_issuerController.isEmpty) {
      _showSnackBar('Please provide issuer signature', isError: true);
      return;
    }

    if (_recipientController.isEmpty) {
      _showSnackBar('Please provide recipient signature', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Export signatures
      final issuerSig = await _issuerController.toPngBytes();
      final recipientSig = await _recipientController.toPngBytes();

      // Generate PDF
      final pdfBytes = await PdfService.generateCustodyCertificate(
        asset: _selectedAsset!,
        employeeName: _employeeNameController.text,
        employeeId: _employeeIdController.text,
        issuerSignature: issuerSig,
        recipientSignature: recipientSig,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Upload PDF
      final pdfUrl =
          await HandoverService.uploadPdf('temp_id', pdfBytes);

      // Create handover record
      final handover = await HandoverService.createHandover(
        assetId: _selectedAsset!.id,
        toUserId: _employeeIdController.text,
        toUserName: _employeeNameController.text,
        issuerSignature: issuerSig,
        recipientSignature: recipientSig,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        pdfUrl: pdfUrl,
      );

      // Share PDF
      final tempFile = XFile.fromData(
        pdfBytes,
        name: 'custody_certificate_${_selectedAsset!.serialNumber}.pdf',
        mimeType: 'application/pdf',
      );
      await Share.shareXFiles([tempFile], text: 'Asset Custody Certificate');

      if (mounted) {
        _showSnackBar('Handover completed successfully!');
        Navigator.pop(context, handover);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Handover'),
        backgroundColor: AppTheme.cardColor(context),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Asset Selection
              _buildSection(
                'Asset Information',
                [
                  if (_selectedAsset == null)
                    _buildAssetPicker()
                  else
                    _buildAssetCard(_selectedAsset!),
                ],
              ),

              const SizedBox(height: 24),

              // Employee Information
              _buildSection(
                'Recipient Information',
                [
                  TextFormField(
                    controller: _employeeNameController,
                    decoration: InputDecoration(
                      labelText: 'Employee Name *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _employeeIdController,
                    decoration: InputDecoration(
                      labelText: 'Employee ID *',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notes
              _buildSection(
                'Notes',
                [
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Additional notes or conditions...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Signatures
              SignaturePadWidget(
                controller: _issuerController,
                label: 'Issuer Signature *',
                height: 150,
              ),

              const SizedBox(height: 24),

              SignaturePadWidget(
                controller: _recipientController,
                label: 'Recipient Signature *',
                height: 150,
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitHandover,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Complete Handover',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildAssetPicker() {
    return StreamBuilder<List<AssetModel>>(
      stream: AssetService.getAssetsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assets = snapshot.data!
            .where((a) => a.status == AssetStatus.inStock || a.status == AssetStatus.assigned)
            .toList();

        return DropdownButtonFormField<AssetModel>(
          decoration: InputDecoration(
            labelText: 'Select Asset *',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: assets
              .map((asset) => DropdownMenuItem(
                    value: asset,
                    child: Text('${asset.name} (${asset.serialNumber})'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedAsset = value);
          },
          validator: (value) => value == null ? 'Please select an asset' : null,
        );
      },
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SN: ${asset.serialNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
