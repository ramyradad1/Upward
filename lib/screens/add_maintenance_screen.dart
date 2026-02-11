import 'package:flutter/material.dart';
import '../models/maintenance_model.dart';
import '../services/maintenance_service.dart';
import '../services/asset_service.dart';
import '../services/profile_service.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';

class AddMaintenanceScreen extends StatefulWidget {
  /// If provided, this screen will create a log entry for this schedule
  final MaintenanceSchedule? logForSchedule;

  const AddMaintenanceScreen({super.key, this.logForSchedule});

  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLogging = false; // false = create schedule, true = log entry
  bool _isSaving = false;

  // Schedule fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _estimatedDurationController = TextEditingController();
  MaintenanceFrequency _frequency = MaintenanceFrequency.monthly;
  MaintenancePriority _priority = MaintenancePriority.medium;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedAssetId;
  String? _selectedAssetName;

  // Log fields
  final _performedByController = TextEditingController();
  final _costController = TextEditingController();
  final _durationController = TextEditingController();
  final _partsController = TextEditingController();
  final _notesController = TextEditingController();
  MaintenanceLogStatus _logStatus = MaintenanceLogStatus.completed;
  DateTime _performedAt = DateTime.now();

  // Assets list for dropdown
  List<AssetModel> _assets = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    if (widget.logForSchedule != null) {
      _isLogging = true;
      _titleController.text = widget.logForSchedule!.title;
      _selectedAssetId = widget.logForSchedule!.assetId;
      _selectedAssetName = widget.logForSchedule!.assetName;
    }

    _loadAssets();
    _loadCurrentUser();
  }

  Future<void> _loadAssets() async {
    final assets = await AssetService.getAssets();
    if (mounted) setState(() => _assets = assets);
  }

  Future<void> _loadCurrentUser() async {
    final profile = await ProfileService.getCurrentProfile();
    if (profile != null && mounted) {
      _performedByController.text = profile['name'] ?? profile['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    _estimatedCostController.dispose();
    _estimatedDurationController.dispose();
    _performedByController.dispose();
    _costController.dispose();
    _durationController.dispose();
    _partsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _animController,
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Toggle: Schedule vs Log
                            if (widget.logForSchedule == null) _buildModeToggle(),
                            const SizedBox(height: 16),
                            _isLogging ? _buildLogForm() : _buildScheduleForm(),
                            const SizedBox(height: 24),
                            _buildSaveButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary(context)),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isLogging ? 'Log Maintenance' : 'New Schedule',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleBtn('Schedule', !_isLogging, () => setState(() => _isLogging = false))),
          Expanded(child: _toggleBtn('Log Entry', _isLogging, () => setState(() => _isLogging = true))),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.primaryGradient() : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.textSecondary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Schedule Form ───────────────────────────────────────────
  Widget _buildScheduleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Basic Info'),
        _buildTextField(_titleController, 'Title', Icons.title_rounded, required: true),
        const SizedBox(height: 12),
        _buildTextField(_descriptionController, 'Description', Icons.notes_rounded, maxLines: 3),
        const SizedBox(height: 20),

        _buildSectionLabel('Configuration'),
        _buildAssetDropdown(),
        const SizedBox(height: 12),
        _buildFrequencySelector(),
        const SizedBox(height: 12),
        _buildPrioritySelector(),
        const SizedBox(height: 12),
        _buildDatePicker('Next Due Date', _nextDueDate, (d) => setState(() => _nextDueDate = d)),
        const SizedBox(height: 20),

        _buildSectionLabel('Assignment & Cost'),
        _buildTextField(_assignedToController, 'Assigned To', Icons.person_outline_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_estimatedCostController, 'Est. Cost (SAR)',
                  Icons.attach_money_rounded, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_estimatedDurationController, 'Duration (min)',
                  Icons.timer_outlined, keyboardType: TextInputType.number),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Log Form ────────────────────────────────────────────────
  Widget _buildLogForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Maintenance Details'),
        _buildTextField(_titleController, 'Title', Icons.title_rounded, required: true),
        const SizedBox(height: 12),
        _buildTextField(_descriptionController, 'Description', Icons.notes_rounded, maxLines: 3),
        const SizedBox(height: 12),
        if (widget.logForSchedule == null) ...[
          _buildAssetDropdown(),
          const SizedBox(height: 12),
        ],
        _buildDatePicker('Performed At', _performedAt, (d) => setState(() => _performedAt = d)),
        const SizedBox(height: 20),

        _buildSectionLabel('Technician & Results'),
        _buildTextField(_performedByController, 'Performed By', Icons.person_rounded, required: true),
        const SizedBox(height: 12),
        _buildLogStatusSelector(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_costController, 'Actual Cost (SAR)',
                  Icons.attach_money_rounded, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(_durationController, 'Duration (min)',
                  Icons.timer_outlined, keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(_partsController, 'Parts Replaced', Icons.build_rounded, maxLines: 2),
        const SizedBox(height: 12),
        _buildTextField(_notesController, 'Notes', Icons.note_alt_rounded, maxLines: 3),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary(context),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textHint(context)),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        filled: true,
        fillColor: AppTheme.inputFill(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.inputBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.inputBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildAssetDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inputBorder(context)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedAssetId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Asset (Optional)',
          labelStyle: TextStyle(color: AppTheme.textHint(context)),
          prefixIcon: Icon(Icons.devices_rounded, color: AppTheme.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: AppTheme.cardColor(context),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text('None', style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ..._assets.map((a) => DropdownMenuItem(
                value: a.id,
                child: Text(a.name, style: TextStyle(color: AppTheme.textPrimary(context))),
              )),
        ],
        onChanged: (val) {
          setState(() {
            _selectedAssetId = val;
            _selectedAssetName = val != null
                ? _assets.firstWhere((a) => a.id == val).name
                : null;
          });
        },
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.inputBorder(context)),
      ),
      child: DropdownButtonFormField<MaintenanceFrequency>(
        value: _frequency,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Frequency',
          labelStyle: TextStyle(color: AppTheme.textHint(context)),
          prefixIcon: Icon(Icons.repeat_rounded, color: AppTheme.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        dropdownColor: AppTheme.cardColor(context),
        items: MaintenanceFrequency.values.map((f) => DropdownMenuItem(
              value: f,
              child: Text(
                MaintenanceSchedule.frequencyDisplayLabel(f),
                style: TextStyle(color: AppTheme.textPrimary(context)),
              ),
            )).toList(),
        onChanged: (val) => setState(() => _frequency = val ?? MaintenanceFrequency.monthly),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: TextStyle(
          fontSize: 13, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 8),
        Row(
          children: MaintenancePriority.values.map((p) {
            final isSelected = _priority == p;
            final color = _getPriorityColor(p);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.inputFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.inputBorder(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      MaintenanceSchedule.priorityDisplayLabel(p),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLogStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: TextStyle(
          fontSize: 13, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 8),
        Row(
          children: MaintenanceLogStatus.values.map((s) {
            final isSelected = _logStatus == s;
            final color = _getLogStatusColor(s);
            final label = s == MaintenanceLogStatus.completed ? 'Completed'
                : s == MaintenanceLogStatus.partial ? 'Partial' : 'Failed';
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _logStatus = s),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.inputFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.inputBorder(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? color : AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.inputFill(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.inputBorder(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 11, color: AppTheme.textHint(context),
                )),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                _isLogging ? 'Save Log Entry' : 'Create Schedule',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    bool success;
    if (_isLogging) {
      success = await _saveLog();
    } else {
      success = await _saveSchedule();
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogging ? 'Maintenance logged!' : 'Schedule created!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<bool> _saveSchedule() async {
    final schedule = MaintenanceSchedule(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      assetId: _selectedAssetId,
      assetName: _selectedAssetName,
      frequency: _frequency,
      priority: _priority,
      assignedTo: _assignedToController.text.trim().isNotEmpty
          ? _assignedToController.text.trim()
          : null,
      nextDueDate: _nextDueDate,
      estimatedCost: double.tryParse(_estimatedCostController.text),
      estimatedDurationMinutes: int.tryParse(_estimatedDurationController.text),
    );
    return MaintenanceService.createSchedule(schedule);
  }

  Future<bool> _saveLog() async {
    final log = MaintenanceLog(
      id: '',
      scheduleId: widget.logForSchedule?.id,
      assetId: _selectedAssetId ?? widget.logForSchedule?.assetId,
      assetName: _selectedAssetName ?? widget.logForSchedule?.assetName,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      performedBy: _performedByController.text.trim(),
      performedAt: _performedAt,
      durationMinutes: int.tryParse(_durationController.text),
      cost: double.tryParse(_costController.text),
      status: _logStatus,
      partsReplaced: _partsController.text.trim().isNotEmpty
          ? _partsController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
    return MaintenanceService.createLog(
      log,
      scheduleId: widget.logForSchedule?.id,
      frequency: widget.logForSchedule?.frequency,
    );
  }

  Color _getPriorityColor(MaintenancePriority p) {
    switch (p) {
      case MaintenancePriority.low: return const Color(0xFF6B7280);
      case MaintenancePriority.medium: return AppTheme.primaryColor;
      case MaintenancePriority.high: return const Color(0xFFF59E0B);
      case MaintenancePriority.critical: return const Color(0xFFEF4444);
    }
  }

  Color _getLogStatusColor(MaintenanceLogStatus s) {
    switch (s) {
      case MaintenanceLogStatus.completed: return const Color(0xFF10B981);
      case MaintenanceLogStatus.partial: return const Color(0xFFF59E0B);
      case MaintenanceLogStatus.failed: return const Color(0xFFEF4444);
    }
  }
}
