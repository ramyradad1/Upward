import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../services/request_service.dart';
import '../services/asset_service.dart';
import '../services/location_service.dart';
import '../models/asset_model.dart';
import '../models/location_model.dart';
import '../theme/app_theme.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  RequestType _selectedType = RequestType.newDevice;
  String? _selectedAssetId;
  String? _selectedAssetName;
  String? _fromLocationId;
  String? _toLocationId;
  bool _isSubmitting = false;

  List<AssetModel> _assets = [];
  List<LocationModel> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final assets = await AssetService.getAssets();
      final locations = await LocationService.getLocations();
      if (mounted) {
        setState(() {
          _assets = assets;
          _locations = locations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Request'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Request Type
                        Text('Request Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textSecondary(context),
                            )),
                        const SizedBox(height: 8),
                        _buildTypeSelector(),

                        const SizedBox(height: 24),

                        // Asset picker (for transfer, repair, return)
                        if (_selectedType != RequestType.newDevice) ...[
                          Text('Select Asset',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textSecondary(context),
                              )),
                          const SizedBox(height: 8),
                          _buildAssetDropdown(),
                          const SizedBox(height: 24),
                        ],

                        // Location pickers (for transfer)
                        if (_selectedType == RequestType.assetTransfer) ...[
                          Text('From Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textSecondary(context),
                              )),
                          const SizedBox(height: 8),
                          _buildLocationDropdown(
                            value: _fromLocationId,
                            onChanged: (v) =>
                                setState(() => _fromLocationId = v),
                            hint: 'Select source location',
                          ),
                          const SizedBox(height: 16),
                          Text('To Location',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textSecondary(context),
                              )),
                          const SizedBox(height: 8),
                          _buildLocationDropdown(
                            value: _toLocationId,
                            onChanged: (v) =>
                                setState(() => _toLocationId = v),
                            hint: 'Select destination location',
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Notes
                        Text('Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textSecondary(context),
                            )),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Add any details about your request...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.borderColor(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.borderColor(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: AppTheme.cardColor(context),
                          ),
                          style: TextStyle(color: AppTheme.textPrimary(context)),
                        ),

                        const SizedBox(height: 32),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Submit Request',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RequestType.values.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(RequestModel.typeDisplayName(type)),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = type;
                // Reset dependent fields
                _selectedAssetId = null;
                _selectedAssetName = null;
                _fromLocationId = null;
                _toLocationId = null;
              });
            }
          },
          selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.borderColor(context),
            ),
          ),
          backgroundColor: AppTheme.cardColor(context),
        );
      }).toList(),
    );
  }

  Widget _buildAssetDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedAssetId,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(context)),
        ),
        filled: true,
        fillColor: AppTheme.cardColor(context),
      ),
      hint: Text('Select an asset',
          style: TextStyle(color: AppTheme.textHint(context))),
      dropdownColor: AppTheme.cardColor(context),
      items: _assets.map((asset) {
        return DropdownMenuItem(
          value: asset.id,
          child: Text('${asset.name} (${asset.serialNumber})',
              style: TextStyle(color: AppTheme.textPrimary(context))),
        );
      }).toList(),
      onChanged: (value) {
        final asset = _assets.firstWhere((a) => a.id == value);
        setState(() {
          _selectedAssetId = value;
          _selectedAssetName = asset.name;
          if (asset.locationId != null) {
            _fromLocationId = asset.locationId;
          }
        });
      },
      validator: (value) {
        if (_selectedType != RequestType.newDevice && value == null) {
          return 'Please select an asset';
        }
        return null;
      },
    );
  }

  Widget _buildLocationDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor(context)),
        ),
        filled: true,
        fillColor: AppTheme.cardColor(context),
      ),
      hint: Text(hint,
          style: TextStyle(color: AppTheme.textHint(context))),
      dropdownColor: AppTheme.cardColor(context),
      items: _locations.map((loc) {
        return DropdownMenuItem(
          value: loc.id,
          child: Text(loc.name,
              style: TextStyle(color: AppTheme.textPrimary(context))),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await RequestService.createRequest(
        type: _selectedType,
        assetId: _selectedAssetId,
        assetName: _selectedAssetName,
        fromLocationId: _fromLocationId,
        toLocationId: _toLocationId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        String errorMessage = e.toString();
        // Clean up error message if it contains "PostgrestException(message: "
        if (errorMessage.contains('PostgrestException(message: ')) {
          errorMessage = errorMessage.split('PostgrestException(message: ')[1].split(',')[0];
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
