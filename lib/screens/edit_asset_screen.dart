import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

class EditAssetScreen extends StatefulWidget {
  final AssetModel asset;
  
  const EditAssetScreen({super.key, required this.asset});

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Device Details
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  
  // Assignment
  bool _isAssigned = false;
  final _assigneeController = TextEditingController();
  final _bagController = TextEditingController();
  final _headsetController = TextEditingController();
  final _headsetSerialController = TextEditingController();
  final _mouseController = TextEditingController();
  final _mouseSerialController = TextEditingController();

  bool _isLoading = false;
  late String _selectedStatus;
  late String _selectedCategory;
  
  XFile? _newDeviceImage;
  XFile? _newIdCardImage;
  PlatformFile? _pickedConfigFile;
  final ImagePicker _picker = ImagePicker();

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

  final List<String> _categories = ['Laptop', 'Desktop', 'Workstation', 'Server', 'Virtual Machine', 'Peripherals', 'Audio', 'Other'];
  final List<String> _statuses = ['In Stock', 'Assigned', 'Under Maintenance', 'Broken'];
  
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
    _loadCompanies();
    _initializeFields();
  }

  Future<void> _loadCompanies() async {
    final companies = await CompanyService.getCompanies();
    if (mounted) {
      setState(() {
        _companies = companies;
        // If asset has a companyId, ensure it's selected, otherwise default
        if (widget.asset.companyId != null && _companies.any((c) => c['id'] == widget.asset.companyId)) {
          _selectedCompanyId = widget.asset.companyId;
        } else if (_companies.isNotEmpty) {
          _selectedCompanyId = _companies.first['id'];
        }
      });
    }
  }

  void _initializeFields() {
    // Parse Name into Brand/Model if possible
    final nameParts = widget.asset.name.split(' ');
    if (nameParts.isNotEmpty) {
      _brandController.text = nameParts.first;
      _modelController.text = nameParts.skip(1).join(' ');
    } else {
      _modelController.text = widget.asset.name;
    }

    _serialController.text = widget.asset.serialNumber;
    _selectedCategory = _categories.contains(widget.asset.category) ? widget.asset.category : 'Other';
    
    // Status Logic
    _selectedStatus = AssetModel.statusToString(widget.asset.status);
    // Map internal status string to display string
    if (_selectedStatus == 'in_stock') {
      _selectedStatus = 'In Stock';
    } else if (_selectedStatus == 'assigned') {
      _selectedStatus = 'Assigned';
    } else if (_selectedStatus == 'repair') {
      _selectedStatus = 'Under Maintenance';
    } else if (_selectedStatus == 'broken') {
      _selectedStatus = 'Broken';
    }

    _isAssigned = widget.asset.status == AssetStatus.assigned;
    
    // Assignment Details
    _assigneeController.text = widget.asset.assignedTo ?? '';
    _bagController.text = widget.asset.bagType ?? '';
    _headsetController.text = widget.asset.headsetType ?? '';
    _headsetSerialController.text = widget.asset.headsetSerial ?? '';
    _mouseController.text = widget.asset.mouseType ?? '';
    _mouseSerialController.text = widget.asset.mouseSerial ?? '';

    // Phase 1: Deep Specs & Network
    _cpuController.text = widget.asset.cpu ?? '';
    _ramController.text = widget.asset.ram ?? '';
    _storageSpecController.text = widget.asset.storageSpec ?? '';
    _hostnameController.text = widget.asset.hostname ?? '';
    _ipAddressController.text = widget.asset.ipAddress ?? '';
    _macAddressController.text = widget.asset.macAddress ?? '';
    _notesController.text = widget.asset.notes ?? '';
    if (widget.asset.secureCredentials != null && widget.asset.secureCredentials!.isNotEmpty) {
      _credentialsController.text = EncryptionService.decryptData(widget.asset.secureCredentials!);
    }
    _selectedLocationId = widget.asset.locationId;
    _selectedLocationName = widget.asset.locationName;
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
    _credentialsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isDeviceImage) async {
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
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isDeviceImage) {
            _newDeviceImage = image;
          } else {
            _newIdCardImage = image;
          }
        });
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

  Future<void> _updateAsset() async {
    if (_brandController.text.isEmpty || _serialController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields'), backgroundColor: AppTheme.accentWarm),
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

    String imageUrl = widget.asset.imageUrl;
    String? idCardUrl = widget.asset.idCardImageUrl;
    String? configFileUrl = widget.asset.configFileUrl;
    String? configFileName = widget.asset.configFileName;

    try {
      // Upload New Device Image
      if (_newDeviceImage != null) {
        final url = await SupabaseService.uploadImage(_newDeviceImage!, 'device_images/${_serialController.text}');
        imageUrl = url;
      }

      // Upload New ID Card Image
      if (_newIdCardImage != null) {
        final url = await SupabaseService.uploadImage(_newIdCardImage!, 'id_cards/${_serialController.text}');
        idCardUrl = url;
      }

      // Upload New Config File
      if (_pickedConfigFile != null) {
        final url = await SupabaseService.uploadFile(_pickedConfigFile!, 'asset_docs/${_serialController.text}');
        configFileUrl = url;
        configFileName = _pickedConfigFile!.name;
      }

      // Determine Status
      AssetStatus finalStatus;
      switch (_selectedStatus) {
        case 'In Stock':
          finalStatus = AssetStatus.inStock;
          break;
        case 'Assigned':
          finalStatus = AssetStatus.assigned;
          break;
        case 'Under Maintenance':
          finalStatus = AssetStatus.repair;
          break;
        case 'Broken':
          finalStatus = AssetStatus.repair; // Map broken to repair
          break;
        default:
          finalStatus = AssetStatus.inStock; // Default or error handling
      }

      // Override status if _isAssigned switch is used
      if (_isAssigned) {
        finalStatus = AssetStatus.assigned;
      } else if (finalStatus == AssetStatus.assigned && !_isAssigned) {
        finalStatus = AssetStatus.inStock;
      }

      String? finalAssigneeName = _isAssigned ? _assigneeController.text : null;

      // Ensure employee exists if assigned
      if (_isAssigned && _assigneeController.text.isNotEmpty) {
        final employee = await EmployeeService.createEmployee(_assigneeController.text, companyId: _selectedCompanyId);
        if (employee != null) {
          finalAssigneeName = employee['name'];
        }
      }

      final updatedAsset = widget.asset.copyWith(
        name: '${_brandController.text} ${_modelController.text}'.trim(),
        category: _selectedCategory,
        serialNumber: _serialController.text,
        status: finalStatus,
        assignedTo: finalAssigneeName,
        bagType: _isAssigned && _bagController.text.isNotEmpty ? _bagController.text : null,
        headsetType: _isAssigned && _headsetController.text.isNotEmpty ? _headsetController.text : null,
        headsetSerial: _isAssigned && _headsetSerialController.text.isNotEmpty ? _headsetSerialController.text : null,
        mouseType: _isAssigned && _mouseController.text.isNotEmpty ? _mouseController.text : null,
        mouseSerial: _isAssigned && _mouseSerialController.text.isNotEmpty ? _mouseSerialController.text : null,
        imageUrl: imageUrl,
        idCardImageUrl: idCardUrl,
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

      await AssetService.updateAsset(updatedAsset);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset updated!'), backgroundColor: AppTheme.accentColor),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppTheme.accentWarm),
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
                    right: -50,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.05),
                        // filter: null,
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
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary(context)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Edit Asset',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.accentWarm),
                            onPressed: () => _confirmDelete(),
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
                                CustomTextField(label: 'Brand', placeholder: 'e.g. Dell', icon: Icons.verified_user_outlined, controller: _brandController),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Model', placeholder: 'e.g. XPS 15', icon: Icons.laptop_mac_rounded, controller: _modelController),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Serial Number', placeholder: 'S/N: 1234...', icon: Icons.qr_code_2_rounded, controller: _serialController),
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
                                Row(
                                  children: [
                                    Expanded(child: CustomTextField(label: 'IP Address', placeholder: 'e.g. 192.168.1.100', icon: Icons.language_rounded, controller: _ipAddressController)),
                                    const SizedBox(width: 12),
                                    Expanded(child: CustomTextField(label: 'MAC Address', placeholder: 'e.g. AA:BB:CC:DD:EE:FF', icon: Icons.router_rounded, controller: _macAddressController)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(label: 'Notes / Wiki', placeholder: 'VLAN, Gateway, troubleshooting...', icon: Icons.notes_rounded, controller: _notesController, maxLines: 3),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        
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
                                                  color: _pickedConfigFile != null || widget.asset.configFileUrl != null 
                                                    ? AppTheme.primaryColor 
                                                    : AppTheme.textHint(context),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _pickedConfigFile?.name 
                                                      ?? widget.asset.configFileName 
                                                      ?? 'No config file',
                                                    style: TextStyle(
                                                      color: (_pickedConfigFile != null || widget.asset.configFileUrl != null) 
                                                        ? AppTheme.textPrimary(context) 
                                                        : AppTheme.textHint(context),
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
                                      margin: const EdgeInsets.only(top: 24),
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

                        // Status & Assignment
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section2Anim),
                          child: FadeTransition(
                            opacity: section2Anim,
                            child: _buildSectionCard(
                              context,
                              title: 'Status & Assignment',
                              icon: Icons.assignment_turned_in_rounded,
                              children: [
                                _buildDropdownLabel(context, 'Device Status'),
                                _buildDropdownContainer(
                                  context,
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      dropdownColor: AppTheme.cardColor(context),
                                      borderRadius: BorderRadius.circular(16),
                                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                      items: _statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedStatus = val!;
                                          _isAssigned = (_selectedStatus == 'Assigned');
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Assign to Employee?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
                                  value: _isAssigned,
                                  onChanged: (val) => setState(() {
                                    _isAssigned = val;
                                    if (_isAssigned && _selectedStatus == 'In Stock') {
                                      _selectedStatus = 'Assigned';
                                    } else if (!_isAssigned && _selectedStatus == 'Assigned') {
                                      _selectedStatus = 'In Stock';
                                    }
                                  }),
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
                                            if (fieldTextEditingController.text != _assigneeController.text && fieldTextEditingController.text.isEmpty) {
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
                                UploadCard(
                                  label: 'Device Photo',
                                  subLabel: 'Change Photo',
                                  icon: Icons.add_a_photo_rounded,
                                  isMain: true,
                                  imageUrl: widget.asset.imageUrl,
                                  imageFile: _newDeviceImage,
                                  onTap: () => _pickImage(true),
                                ),
                                const SizedBox(height: 16),
                                if (_isAssigned)
                                  UploadCard(
                                    label: 'ID Card Photo',
                                    subLabel: 'Add/Change ID Card',
                                    icon: Icons.badge_rounded,
                                    imageUrl: widget.asset.idCardImageUrl,
                                    imageFile: _newIdCardImage,
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
                    onPressed: _isLoading ? null : _updateAsset,
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
                            Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to delete this asset? This action cannot be undone.'),
        backgroundColor: AppTheme.cardColor(context),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
        contentTextStyle: TextStyle(fontSize: 16, color: AppTheme.textSecondary(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await AssetService.deleteAsset(widget.asset.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asset deleted'), backgroundColor: AppTheme.accentColor),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppTheme.accentWarm),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.accentWarm, fontWeight: FontWeight.bold)),
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
}
