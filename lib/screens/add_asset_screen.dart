import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/upload_card.dart';
import '../models/asset_model.dart';
import '../models/location_model.dart';
import '../services/asset_service.dart';
import '../services/supabase_service.dart';
import '../services/company_service.dart';
import '../services/employee_service.dart';
import '../services/location_service.dart';
import '../services/encryption_service.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Device Details
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  
  // Assignment & Accessories
  bool _isAssigned = false;
  final _assigneeController = TextEditingController();
  final _bagController = TextEditingController();
  final _headsetController = TextEditingController();
  final _headsetSerialController = TextEditingController();
  final _mouseController = TextEditingController();
  final _mouseSerialController = TextEditingController();

  // Phase 1: Deep Specs & Network
  final _cpuController = TextEditingController();
  final _ramController = TextEditingController();
  final _storageSpecController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _ipAddressController = TextEditingController();
  final _macAddressController = TextEditingController();
  final _notesController = TextEditingController();
  final _credentialsController = TextEditingController();
  bool _isCredentialsVisible = false;
  String? _selectedLocationId;
  String? _selectedLocationName;

  bool _isLoading = false;
  String _selectedCategory = 'Laptop';
  final List<XFile> _deviceImages = [];
  XFile? _custodyImage;
  XFile? _idCardImage;
  PlatformFile? _pickedConfigFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['Laptop', 'Desktop', 'Workstation', 'Server', 'Virtual Machine', 'Peripherals', 'Audio', 'Other'];
  
  String? _selectedCompanyId;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _assigneeController.dispose();
    _bagController.dispose();
    _headsetController.dispose();
    _headsetSerialController.dispose();
    _mouseController.dispose();
    _mouseSerialController.dispose();
    _cpuController.dispose();
    _ramController.dispose();
    _storageSpecController.dispose();
    _hostnameController.dispose();
    _ipAddressController.dispose();
    _macAddressController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isDeviceImage, {bool isCustody = false}) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                ),
                title: Text('Camera', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                subtitle: Text('Take a new photo', style: TextStyle(color: AppTheme.textSecondary(context))),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                  leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                ),
                title: Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                subtitle: Text('Choose from gallery', style: TextStyle(color: AppTheme.textSecondary(context))),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      if (isDeviceImage && source == ImageSource.gallery) {
        // Multi-image picker for device images from gallery
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (images.isNotEmpty) {
          setState(() {
            _deviceImages.addAll(images);
          });
        }
      } else {
        // Single image picker
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            if (isDeviceImage) {
              _deviceImages.add(image);
            } else if (isCustody) {
              _custodyImage = image;
            } else {
              _idCardImage = image;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: AppTheme.accentWarm,
          ),
        );
      }
    }
  }

  Future<void> _pickConfigFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['conf', 'cfg', 'txt', 'backup', 'json', 'yaml', 'xml', 'pdf', 'docx'],
      );
      if (result != null) {
        setState(() {
          _pickedConfigFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppTheme.accentWarm),
        );
      }
    }
  }

  Future<void> _saveAsset() async {
    if (_brandController.text.isEmpty || 
        _modelController.text.isEmpty || 
        _serialController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppTheme.accentWarm),
      );
      return;
    }

    if (_isAssigned && _assigneeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter employee name'), backgroundColor: AppTheme.accentWarm),
      );
      return;
    }

    setState(() => _isLoading = true);

    List<String> imageUrls = [];
    String imageUrl = 'https://via.placeholder.com/300x200?text=$_selectedCategory';
    String? custodyUrl;
    String? idCardUrl;
    String? configFileUrl;
    String? configFileName;

    try {
      // Upload Device Images
      for (var i = 0; i < _deviceImages.length; i++) {
        final image = _deviceImages[i];
        final url = await SupabaseService.uploadImage(image, 'device_images/${_serialController.text}_$i');
        imageUrls.add(url);
      }
      
      if (imageUrls.isNotEmpty) {
        imageUrl = imageUrls.first;
      }

      // Upload Custody Image
      if (_custodyImage != null) {
        final url = await SupabaseService.uploadImage(_custodyImage!, 'custody_docs/${_serialController.text}');
        custodyUrl = url;
      }

      // Upload ID Card Image
      if (_idCardImage != null) {
        final url = await SupabaseService.uploadImage(_idCardImage!, 'id_cards/${_serialController.text}');
        idCardUrl = url;
      }

      // Upload Config File
      if (_pickedConfigFile != null) {
        final url = await SupabaseService.uploadFile(_pickedConfigFile!, 'asset_docs/${_serialController.text}');
        configFileUrl = url;
        configFileName = _pickedConfigFile!.name;
      }

      // Ensure employee exists if assigned
      String? finalAssigneeName = _isAssigned ? _assigneeController.text : null;
      
      if (_isAssigned && _assigneeController.text.isNotEmpty) {
        final employee = await EmployeeService.createEmployee(_assigneeController.text, companyId: _selectedCompanyId);
        if (employee != null) {
          finalAssigneeName = employee['name'];
        }
      }

      final asset = AssetModel(
        id: '',
        name: '${_brandController.text} ${_modelController.text}',
        category: _selectedCategory,
        serialNumber: _serialController.text,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        custodyImageUrl: custodyUrl,
        idCardImageUrl: idCardUrl,
        status: _isAssigned ? AssetStatus.assigned : AssetStatus.inStock,
        assignedTo: finalAssigneeName,
        bagType: _isAssigned && _bagController.text.isNotEmpty ? _bagController.text : null,
        headsetType: _isAssigned && _headsetController.text.isNotEmpty ? _headsetController.text : null,
        headsetSerial: _isAssigned && _headsetSerialController.text.isNotEmpty ? _headsetSerialController.text : null,
        mouseType: _isAssigned && _mouseController.text.isNotEmpty ? _mouseController.text : null,
        mouseSerial: _isAssigned && _mouseSerialController.text.isNotEmpty ? _mouseSerialController.text : null,
        companyId: _selectedCompanyId,
        // Phase 1: Deep Specs & Network
        locationId: _selectedLocationId,
        locationName: _selectedLocationName,
        cpu: _cpuController.text.isNotEmpty ? _cpuController.text : null,
        ram: _ramController.text.isNotEmpty ? _ramController.text : null,
        storageSpec: _storageSpecController.text.isNotEmpty ? _storageSpecController.text : null,
        hostname: _hostnameController.text.isNotEmpty ? _hostnameController.text : null,
        ipAddress: _ipAddressController.text.isNotEmpty ? _ipAddressController.text : null,
        macAddress: _macAddressController.text.isNotEmpty ? _macAddressController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        // Phase 2
        configFileUrl: configFileUrl,
        configFileName: configFileName,
        secureCredentials: _credentialsController.text.isNotEmpty 
            ? EncryptionService.encryptData(_credentialsController.text) 
            : null,
      );

      await AssetService.addAsset(asset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset added successfully!'), backgroundColor: AppTheme.accentColor),
        );
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to add asset: $e';
        if (e.toString().contains('duplicate key')) {
          errorMsg = 'Asset with this serial number already exists.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppTheme.accentWarm),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final headerAnim = AppTheme.staggerAnimation(_animController, 0);
    final section1Anim = AppTheme.staggerAnimation(_animController, 1);
    final section2Anim = AppTheme.staggerAnimation(_animController, 2);
    final sectionSpecsAnim = AppTheme.staggerAnimation(_animController, 3);
    final section3Anim = AppTheme.staggerAnimation(_animController, 4);
    final btnAnim = AppTheme.staggerAnimation(_animController, 5);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background
          RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient(context),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -50,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.05),
                        // filter: null, // Removed blur for performance

                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(headerAnim),
                  child: FadeTransition(
                    opacity: headerAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.glassColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor(context)),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/dashboard');
                                }
                              },
                              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary(context)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Add New Asset',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Form Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      children: [
                        // Device Details Section
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section1Anim),
                          child: FadeTransition(
                            opacity: section1Anim,
                            child: _buildSectionCard(
                              context,
                              title: 'Device Details',
                              icon: Icons.devices_other_rounded,
                              children: [
                                _buildDropdownLabel(context, 'Company'),
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: CompanyService.getCompaniesStream(),
                                  initialData: CompanyService.currentCompanies,
                                  builder: (context, snapshot) {
                                    final companies = snapshot.data ?? [];
                                    
                                    // If we have companies but none selected, select the first one
                                    if (companies.isNotEmpty && _selectedCompanyId == null) {
                                      // Defer setState
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) setState(() => _selectedCompanyId = companies.first['id']);
                                      });
                                    }

                                    return _buildDropdownContainer(
                                      context,
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _selectedCompanyId,
                                          isExpanded: true,
                                          hint: Text('Select Company', style: TextStyle(color: AppTheme.textHint(context))),
                                          dropdownColor: AppTheme.cardColor(context),
                                          borderRadius: BorderRadius.circular(16),
                                          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                          items: companies.map((company) {
                                            return DropdownMenuItem<String>(
                                              value: company['id'] as String,
                                              child: Text(company['name'] ?? 'Unnamed'),
                                            );
                                          }).toList(),
                                          onChanged: (val) => setState(() => _selectedCompanyId = val),
                                        ),
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownLabel(context, 'Category'),
                                _buildDropdownContainer(
                                  context, 
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isExpanded: true,
                                      dropdownColor: AppTheme.cardColor(context),
                                      borderRadius: BorderRadius.circular(16),
                                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                      onChanged: (val) => setState(() => _selectedCategory = val!),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Brand', placeholder: 'e.g. Dell, Apple', icon: Icons.verified_user_outlined, controller: _brandController),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Model', placeholder: 'e.g. XPS 15', icon: Icons.laptop_mac_rounded, controller: _modelController),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Serial Number', placeholder: 'S/N: 4820...', icon: Icons.qr_code_2_rounded, controller: _serialController),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // Specs & Network Section (Phase 1)
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(sectionSpecsAnim),
                          child: FadeTransition(
                            opacity: sectionSpecsAnim,
                            child: _buildSectionCard(
                              context,
                              title: 'Specs & Network',
                              icon: Icons.memory_rounded,
                              children: [
                                // Location Picker
                                _buildDropdownLabel(context, 'Location'),
                                StreamBuilder<List<LocationModel>>(
                                  stream: LocationService.getLocationsStream(),
                                  builder: (context, snapshot) {
                                    final locations = snapshot.data ?? [];
                                    return _buildDropdownContainer(
                                      context,
                                      DropdownButtonHideUnderline(
                                        child: DropdownButton<String?>(
                                          value: _selectedLocationId,
                                          isExpanded: true,
                                          hint: Text('No Location', style: TextStyle(color: AppTheme.textHint(context))),
                                          dropdownColor: AppTheme.cardColor(context),
                                          borderRadius: BorderRadius.circular(16),
                                          style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                          items: [
                                            DropdownMenuItem<String?>(value: null, child: Text('No Location', style: TextStyle(color: AppTheme.textHint(context)))),
                                            ...locations.map((loc) => DropdownMenuItem<String?>(
                                              value: loc.id,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.location_on_rounded, size: 16, color: AppTheme.primaryColor),
                                                  const SizedBox(width: 6),
                                                  Expanded(child: Text('${LocationModel.typeToString(loc.type)}: ${loc.name}', overflow: TextOverflow.ellipsis)),
                                                ],
                                              ),
                                            )),
                                          ],
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedLocationId = val;
                                              _selectedLocationName = locations.where((l) => l.id == val).firstOrNull?.name;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Hardware Specs
                                Row(
                                  children: [
                                    Expanded(child: CustomTextField(label: 'CPU', placeholder: 'e.g. i7-12700H', icon: Icons.memory_rounded, controller: _cpuController)),
                                    const SizedBox(width: 12),
                                    Expanded(child: CustomTextField(label: 'RAM', placeholder: 'e.g. 16GB', icon: Icons.storage_rounded, controller: _ramController)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: CustomTextField(label: 'Storage', placeholder: 'e.g. 512GB SSD', icon: Icons.sd_storage_rounded, controller: _storageSpecController)),
                                    const SizedBox(width: 12),
                                    Expanded(child: CustomTextField(label: 'Hostname', placeholder: 'e.g. PC-DEV-001', icon: Icons.computer_rounded, controller: _hostnameController)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Network
                                Row(
                                  children: [
                                    Expanded(child: CustomTextField(label: 'IP Address', placeholder: 'e.g. 192.168.1.100', icon: Icons.language_rounded, controller: _ipAddressController)),
                                    const SizedBox(width: 12),
                                    Expanded(child: CustomTextField(label: 'MAC Address', placeholder: 'e.g. AA:BB:CC:DD:EE:FF', icon: Icons.router_rounded, controller: _macAddressController)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Notes / Asset Wiki
                                CustomTextField(label: 'Notes / Wiki', placeholder: 'VLAN, Gateway, troubleshooting steps...', icon: Icons.notes_rounded, controller: _notesController, maxLines: 3),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Configuration & Security (Phase 2)
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(sectionSpecsAnim),
                          child: FadeTransition(
                            opacity: sectionSpecsAnim,
                            child: _buildSectionCard(
                              context,
                              title: 'Configuration & Security',
                              icon: Icons.security_rounded,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Config Backup', 
                                            style: TextStyle(
                                              fontSize: 14, 
                                              fontWeight: FontWeight.w600, 
                                              color: AppTheme.textSecondary(context)
                                            )
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.inputFill(context),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.inputBorder(context)),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.file_present_rounded, 
                                                  color: _pickedConfigFile != null ? AppTheme.primaryColor : AppTheme.textHint(context),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _pickedConfigFile?.name ?? 'No config file selected',
                                                    style: TextStyle(
                                                      color: _pickedConfigFile != null ? AppTheme.textPrimary(context) : AppTheme.textHint(context),
                                                      fontSize: 14,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (_pickedConfigFile != null)
                                                  GestureDetector(
                                                    onTap: () => setState(() => _pickedConfigFile = null),
                                                    child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary(context)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      margin: const EdgeInsets.only(top: 24), // Align with input box
                                      child: ElevatedButton.icon(
                                        onPressed: _pickConfigFile,
                                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                                        label: const Text('Upload'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.cardColor(context),
                                          foregroundColor: AppTheme.primaryColor,
                                          elevation: 0,
                                          side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Secure Credentials', 
                                  placeholder: 'admin / p@ssw0rd123', 
                                  icon: Icons.vpn_key_rounded, 
                                  controller: _credentialsController,
                                  obscureText: !_isCredentialsVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isCredentialsVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: AppTheme.iconColor(context),
                                    ),
                                    onPressed: () => setState(() => _isCredentialsVisible = !_isCredentialsVisible),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Credentials are encrypted before storage.',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textHint(context), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Assignment & Accessories Section
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section2Anim),
                          child: FadeTransition(
                            opacity: section2Anim,
                            child: _buildSectionCard(
                              context,
                              title: 'Assignment',
                              icon: Icons.assignment_ind_rounded,
                              children: [
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Assign to Employee?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                                  value: _isAssigned,
                                  onChanged: (val) => setState(() => _isAssigned = val),
                                  activeTrackColor: AppTheme.primaryColor,
                                ),
                                
                                if (_isAssigned) ...[
                                  const SizedBox(height: 12),
                                  _buildDropdownLabel(context, 'Employee Name'),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputFill(context),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.inputBorder(context)),
                                    ),
                                    child: StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: EmployeeService.getEmployeesStream(),
                                      builder: (context, snapshot) {
                                        final employees = snapshot.data ?? [];
                                        
                                        return Autocomplete<Map<String, dynamic>>(
                                          optionsBuilder: (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text == '') {
                                              return const Iterable<Map<String, dynamic>>.empty();
                                            }
                                            return employees.where((Map<String, dynamic> option) {
                                              return option['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
                                            });
                                          },
                                          displayStringForOption: (Map<String, dynamic> option) => option['name'],
                                          onSelected: (Map<String, dynamic> selection) {
                                            _assigneeController.text = selection['name'];
                                          },
                                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                                            if (fieldTextEditingController.text != _assigneeController.text) {
                                                fieldTextEditingController.text = _assigneeController.text;
                                            }

                                            fieldTextEditingController.addListener(() {
                                              _assigneeController.text = fieldTextEditingController.text;
                                            });

                                            return TextField(
                                              controller: fieldTextEditingController,
                                              focusNode: fieldFocusNode,
                                              style: TextStyle(color: AppTheme.textPrimary(context)),
                                              decoration: InputDecoration(
                                                hintText: 'e.g. John Doe',
                                                hintStyle: TextStyle(color: AppTheme.textHint(context)),
                                                prefixIcon: Icon(Icons.person_rounded, color: AppTheme.iconColor(context)),
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              ),
                                            );
                                          },
                                          optionsViewBuilder: (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 8,
                                                color: AppTheme.cardColor(context),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  width: 300, 
                                                  constraints: const BoxConstraints(maxHeight: 250),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder: (BuildContext context, int index) {
                                                      final option = options.elementAt(index);
                                                      return ListTile(
                                                        title: Text(option['name'], style: TextStyle(color: AppTheme.textPrimary(context))),
                                                        hoverColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                        onTap: () {
                                                          onSelected(option);
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Icon(Icons.keyboard_rounded, size: 16, color: AppTheme.textSecondary(context)),
                                        const SizedBox(width: 8),
                                        Text('Accessories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary(context))),
                                      ],
                                    ),
                                  ),
                                  
                                  CustomTextField(label: 'Bag', placeholder: 'e.g. Dell Backpack', icon: Icons.backpack_outlined, controller: _bagController),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(child: CustomTextField(label: 'Headset Type', placeholder: 'Model', icon: Icons.headset_rounded, controller: _headsetController)),
                                      const SizedBox(width: 12),
                                      Expanded(child: CustomTextField(label: 'Headset S/N', placeholder: 'S/N', icon: Icons.qr_code, controller: _headsetSerialController)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(child: CustomTextField(label: 'Mouse Type', placeholder: 'Model', icon: Icons.mouse_rounded, controller: _mouseController)),
                                      const SizedBox(width: 12),
                                      Expanded(child: CustomTextField(label: 'Mouse S/N', placeholder: 'S/N', icon: Icons.qr_code, controller: _mouseSerialController)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Images Section
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section3Anim),
                          child: FadeTransition(
                            opacity: section3Anim,
                            child: _buildSectionCard(
                              context,
                              title: 'Images',
                              icon: Icons.image_rounded,
                              children: [
                                _buildImageGrid(context),
                                const SizedBox(height: 16),
                                UploadCard(
                                  label: 'Custody Document',
                                  subLabel: 'Add Document',
                                  icon: Icons.description_rounded,
                                  imageFile: _custodyImage,
                                  onTap: () => _pickImage(false, isCustody: true),
                                ),
                                const SizedBox(height: 16),
                                if (_isAssigned)
                                  UploadCard(
                                    label: 'ID Card Photo',
                                    subLabel: 'Add ID Card',
                                    icon: Icons.badge_rounded,
                                    imageFile: _idCardImage,
                                    onTap: () => _pickImage(false),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Sticky Footer Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(btnAnim),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: isDark 
                      ? [AppTheme.backgroundDark, AppTheme.backgroundDark.withValues(alpha: 0.95), AppTheme.backgroundDark.withValues(alpha: 0)]
                      : [AppTheme.backgroundLight, AppTheme.backgroundLight.withValues(alpha: 0.95), AppTheme.backgroundLight.withValues(alpha: 0)],
                    stops: const [0, 0.6, 1],
                  ),
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAsset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 22),
                            SizedBox(width: 8),
                            Text('Register Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
  
  Widget _buildDropdownContainer(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inputBorder(context)),
      ),
      child: child,
    );
  }
  
  Widget _buildImageGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Device Images', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary(context))),
            TextButton.icon(
              onPressed: () => _pickImage(true),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Add Photos'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_deviceImages.isEmpty)
          UploadCard(
            label: 'Device Photos',
            subLabel: 'Select Photos',
            icon: Icons.add_a_photo_rounded,
            isMain: true,
            imageFile: null,
            onTap: () => _pickImage(true),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _deviceImages.length + 1,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == _deviceImages.length) {
                  return AspectRatio(
                    aspectRatio: 1,
                    child: InkWell(
                      onTap: () => _pickImage(true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputFill(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context), style: BorderStyle.solid),
                        ),
                        child: Icon(Icons.add_rounded, color: AppTheme.textSecondary(context), size: 32),
                      ),
                    ),
                  );
                }
                
                final image = _deviceImages[index];
                return Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(File(image.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _deviceImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
