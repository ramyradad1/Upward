import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/license_model.dart';
import '../services/license_service.dart';
import '../services/encryption_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  LicenseType? _filterType;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<LicenseModel> _filterLicenses(List<LicenseModel> licenses) {
    return licenses.where((l) {
      final matchesSearch = _searchQuery.isEmpty ||
          l.name.toLowerCase().contains(_searchQuery) ||
          (l.vendor?.toLowerCase().contains(_searchQuery) ?? false);
      final matchesType = _filterType == null || l.type == _filterType;
      return matchesSearch && matchesType;
    }).toList();
  }

  Color _utilizationColor(double utilization) {
    if (utilization >= 95) return AppTheme.accentWarm;
    if (utilization >= 80) return const Color(0xFFFFA726);
    return AppTheme.accentColor;
  }

  Color _expiryColor(LicenseModel license) {
    if (license.isExpired) return AppTheme.accentWarm;
    if (license.isExpiringSoon) return const Color(0xFFFFA726);
    return AppTheme.accentColor;
  }

  IconData _typeIcon(LicenseType type) {
    switch (type) {
      case LicenseType.saas:
        return Icons.cloud_rounded;
      case LicenseType.cloud:
        return Icons.cloud_queue_rounded;
      case LicenseType.software:
        return Icons.desktop_windows_rounded;
      case LicenseType.other:
        return Icons.extension_rounded;
    }
  }

  Color _typeColor(LicenseType type) {
    switch (type) {
      case LicenseType.saas:
        return AppTheme.primaryColor;
      case LicenseType.cloud:
        return AppTheme.accentColor;
      case LicenseType.software:
        return const Color(0xFFFFA726);
      case LicenseType.other:
        return AppTheme.accentWarm;
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.accentWarm : AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showAddEditDialog({LicenseModel? license}) async {
    final isEditing = license != null;
    final nameController = TextEditingController(text: license?.name ?? '');
    final vendorController = TextEditingController(text: license?.vendor ?? '');
    final totalSeatsController = TextEditingController(text: license?.totalSeats.toString() ?? '1');
    final usedSeatsController = TextEditingController(text: license?.usedSeats.toString() ?? '0');
    final costController = TextEditingController(text: license?.costPerSeat?.toString() ?? '');
    final keyController = TextEditingController(
      text: license?.licenseKey != null ? EncryptionService.decryptData(license!.licenseKey!) : '',
    );
    final notesController = TextEditingController(text: license?.notes ?? '');

    LicenseType selectedType = license?.type ?? LicenseType.saas;
    BillingCycle selectedCycle = license?.billingCycle ?? BillingCycle.monthly;
    DateTime? purchaseDate = license?.purchaseDate;
    DateTime? expiryDate = license?.expiryDate;
    bool isKeyVisible = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppTheme.cardColor(context),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: Colors.white, size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit License' : 'Add License',
                          style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Form body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'License Name',
                          placeholder: 'e.g., Microsoft 365 Business',
                          icon: Icons.badge_rounded,
                          controller: nameController,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Vendor',
                          placeholder: 'e.g., Microsoft, Adobe',
                          icon: Icons.business_rounded,
                          controller: vendorController,
                        ),
                        const SizedBox(height: 16),

                        // License type
                        Text('License Type', style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: AppTheme.textSecondary(context),
                        )),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.inputBorder(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LicenseType>(
                              value: selectedType,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(16),
                              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                              items: LicenseType.values.map((t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(_typeIcon(t), color: _typeColor(t), size: 18),
                                    const SizedBox(width: 10),
                                    Text(LicenseModel.typeDisplayName(t)),
                                  ],
                                ),
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedType = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Billing cycle
                        Text('Billing Cycle', style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: AppTheme.textSecondary(context),
                        )),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.inputBorder(context)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BillingCycle>(
                              value: selectedCycle,
                              isExpanded: true,
                              dropdownColor: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(16),
                              style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                              items: BillingCycle.values.map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(LicenseModel.billingCycleDisplayName(c)),
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedCycle = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Seats
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Total Seats',
                                placeholder: '1',
                                icon: Icons.people_rounded,
                                controller: totalSeatsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Used Seats',
                                placeholder: '0',
                                icon: Icons.person_rounded,
                                controller: usedSeatsController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cost
                        CustomTextField(
                          label: 'Cost Per Seat (\$)',
                          placeholder: '0.00',
                          icon: Icons.attach_money_rounded,
                          controller: costController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),

                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                ctx,
                                label: 'Purchase Date',
                                date: purchaseDate,
                                onSelect: (d) => setDialogState(() => purchaseDate = d),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDatePicker(
                                ctx,
                                label: 'Expiry Date',
                                date: expiryDate,
                                onSelect: (d) => setDialogState(() => expiryDate = d),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // License key
                        CustomTextField(
                          label: 'License Key',
                          placeholder: 'XXXX-XXXX-XXXX-XXXX',
                          icon: Icons.vpn_key_rounded,
                          controller: keyController,
                          obscureText: !isKeyVisible,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isKeyVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppTheme.iconColor(context),
                            ),
                            onPressed: () => setDialogState(() => isKeyVisible = !isKeyVisible),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'License key is encrypted before storage.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textHint(context), fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        CustomTextField(
                          label: 'Notes',
                          placeholder: 'Additional info...',
                          icon: Icons.notes_rounded,
                          controller: notesController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.borderColor(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(context))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              _showSnack('License name is required', isError: true);
                              return;
                            }

                            final encryptedKey = keyController.text.isNotEmpty
                                ? EncryptionService.encryptData(keyController.text)
                                : null;

                            final model = LicenseModel(
                              id: license?.id ?? const Uuid().v4(),
                              name: nameController.text.trim(),
                              type: selectedType,
                              vendor: vendorController.text.trim().isEmpty ? null : vendorController.text.trim(),
                              totalSeats: int.tryParse(totalSeatsController.text) ?? 1,
                              usedSeats: int.tryParse(usedSeatsController.text) ?? 0,
                              purchaseDate: purchaseDate,
                              expiryDate: expiryDate,
                              costPerSeat: double.tryParse(costController.text),
                              billingCycle: selectedCycle,
                              licenseKey: encryptedKey,
                              notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              createdAt: license?.createdAt ?? DateTime.now(),
                            );

                            bool success;
                            if (isEditing) {
                              success = await LicenseService.updateLicense(model);
                            } else {
                              success = (await LicenseService.createLicense(model)) != null;
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            _showSnack(
                              success
                                  ? (isEditing ? 'License updated' : 'License added')
                                  : 'Something went wrong',
                              isError: !success,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: Text(isEditing ? 'Save Changes' : 'Add License',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext ctx, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13,
          color: AppTheme.textSecondary(context),
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primaryColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) onSelect(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputFill(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.inputBorder(context)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, 
                    color: date != null ? AppTheme.primaryColor : AppTheme.textHint(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select...',
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? AppTheme.textPrimary(context) : AppTheme.textHint(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteLicense(LicenseModel license) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.cardColor(context),
        title: Text('Delete License', style: TextStyle(color: AppTheme.textPrimary(context))),
        content: Text(
          'Delete "${license.name}"? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentWarm,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await LicenseService.deleteLicense(license.id);
      _showSnack(
        success ? 'License deleted' : 'Failed to delete',
        isError: !success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.glassColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppTheme.textPrimary(context)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Licenses', style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 22,
          color: AppTheme.textPrimary(context),
        )),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => _showAddEditDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: AppTheme.textPrimary(context)),
                          decoration: InputDecoration(
                            hintText: 'Search licenses...',
                            hintStyle: TextStyle(color: AppTheme.textHint(context)),
                            prefixIcon: Icon(Icons.search_rounded, color: AppTheme.iconColor(context), size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<LicenseType?>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppTheme.cardColor(context),
                      onSelected: (val) => setState(() => _filterType = val),
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: null,
                          child: Text('All Types', style: TextStyle(
                            color: _filterType == null ? AppTheme.primaryColor : AppTheme.textPrimary(context),
                            fontWeight: _filterType == null ? FontWeight.bold : FontWeight.normal,
                          )),
                        ),
                        ...LicenseType.values.map((t) => PopupMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(_typeIcon(t), color: _typeColor(t), size: 18),
                              const SizedBox(width: 8),
                              Text(LicenseModel.typeDisplayName(t), style: TextStyle(
                                color: _filterType == t ? AppTheme.primaryColor : AppTheme.textPrimary(context),
                                fontWeight: _filterType == t ? FontWeight.bold : FontWeight.normal,
                              )),
                            ],
                          ),
                        )),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _filterType != null
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : AppTheme.glassColor(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _filterType != null
                                ? AppTheme.primaryColor.withValues(alpha: 0.5)
                                : AppTheme.borderColor(context),
                          ),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: _filterType != null ? AppTheme.primaryColor : AppTheme.iconColor(context),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // License list
              Expanded(
                child: StreamBuilder<List<LicenseModel>>(
                  stream: LicenseService.getLicensesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                      );
                    }

                    final allLicenses = snapshot.data ?? [];
                    final licenses = _filterLicenses(allLicenses);

                    if (allLicenses.isEmpty) {
                      return _buildEmptyState();
                    }

                    if (licenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textHint(context)),
                            const SizedBox(height: 12),
                            Text('No matching licenses', style: TextStyle(
                              fontSize: 16, color: AppTheme.textSecondary(context),
                            )),
                          ],
                        ),
                      );
                    }

                    // Summary cards
                    final totalCost = allLicenses.fold(0.0, (s, l) => s + (l.totalCost ?? 0));
                    final totalSeats = allLicenses.fold(0, (s, l) => s + l.totalSeats);
                    final usedSeats = allLicenses.fold(0, (s, l) => s + l.usedSeats);
                    final expiring = allLicenses.where((l) => l.isExpiringSoon).length;

                    return Column(
                      children: [
                        // Stats row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              _buildStatCard('Total', allLicenses.length.toString(), Icons.layers_rounded, AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              _buildStatCard('Seats', '$usedSeats/$totalSeats', Icons.people_rounded, AppTheme.accentColor),
                              const SizedBox(width: 8),
                              _buildStatCard('Expiring', expiring.toString(), Icons.warning_rounded, const Color(0xFFFFA726)),
                              const SizedBox(width: 8),
                              _buildStatCard('Cost', '\$${totalCost.toStringAsFixed(0)}', Icons.attach_money_rounded, AppTheme.accentWarm),
                            ],
                          ),
                        ),

                        // License cards
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: licenses.length,
                            itemBuilder: (context, index) {
                              final license = licenses[index];
                              final anim = AppTheme.staggerAnimation(_animController, index);
                              return SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: _buildLicenseCard(license),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.glassColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            )),
            Text(label, style: TextStyle(
              fontSize: 10, color: AppTheme.textHint(context),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseCard(LicenseModel license) {
    final utilization = license.seatUtilization;
    final daysLeft = license.expiryDate?.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showAddEditDialog(license: license),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _typeColor(license.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcon(license.type), color: _typeColor(license.type), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(license.name, style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          )),
                          if (license.vendor != null)
                            Text(license.vendor!, style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary(context),
                            )),
                        ],
                      ),
                    ),
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor(license.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _typeColor(license.type).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        LicenseModel.typeDisplayName(license.type),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor(license.type)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: AppTheme.cardColor(context),
                      icon: Icon(Icons.more_vert_rounded, color: AppTheme.iconColor(context), size: 20),
                      onSelected: (val) {
                        if (val == 'edit') _showAddEditDialog(license: license);
                        if (val == 'delete') _deleteLicense(license);
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(value: 'edit', child: Row(children: [
                          Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text('Edit', style: TextStyle(color: AppTheme.textPrimary(context))),
                        ])),
                        PopupMenuItem(value: 'delete', child: Row(children: [
                          const Icon(Icons.delete_rounded, size: 18, color: AppTheme.accentWarm),
                          const SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppTheme.textPrimary(context))),
                        ])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Seat utilization bar
                Row(
                  children: [
                    Icon(Icons.people_rounded, size: 14, color: AppTheme.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text('${license.usedSeats}/${license.totalSeats} seats',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: utilization / 100,
                          backgroundColor: AppTheme.borderColor(context),
                          valueColor: AlwaysStoppedAnimation(_utilizationColor(utilization)),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${utilization.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _utilizationColor(utilization)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Footer info
                Row(
                  children: [
                    if (license.costPerSeat != null) ...[
                      Icon(Icons.attach_money_rounded, size: 14, color: AppTheme.textHint(context)),
                      Text('\$${license.totalCost?.toStringAsFixed(2)}/total',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),

                    if (license.expiryDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _expiryColor(license).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              license.isExpired ? Icons.error_rounded : Icons.schedule_rounded,
                              size: 12, color: _expiryColor(license),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              license.isExpired
                                  ? 'Expired'
                                  : '${daysLeft}d left',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _expiryColor(license)),
                            ),
                          ],
                        ),
                      ),

                    if (license.billingCycle != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        LicenseModel.billingCycleDisplayName(license.billingCycle!),
                        style: TextStyle(fontSize: 11, color: AppTheme.textHint(context)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_membership_rounded, size: 64, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          Text('No Licenses Yet', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          )),
          const SizedBox(height: 8),
          Text('Add your first software license\nto start tracking.', textAlign: TextAlign.center, style: TextStyle(
            fontSize: 14, color: AppTheme.textSecondary(context), height: 1.5,
          )),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add License'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
