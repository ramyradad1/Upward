import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import '../services/company_service.dart'; // To get company names
import '../theme/app_theme.dart';
import 'create_user_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  late AnimationController _animController;
  
  // Cache companies to map ID to Name
  Map<String, String> _companyNames = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
    _searchController.addListener(_onSearchChanged);
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    final companies = await CompanyService.getCompanies();
    if (mounted) {
      setState(() {
        _companyNames = {
          for (var c in companies) c['id'] as String: c['name'] as String
        };
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _filterEmployees(List<Map<String, dynamic>> employees) {
    if (_searchQuery.isEmpty) return employees;
    return employees
        .where((e) => (e['name'] as String).toLowerCase().contains(_searchQuery))
        .toList();
  }

  // NOTE: Delete logic for employees might be missing in EmployeeService
  // For now, I'll just implemented it if available, or skip delete for now given the prompt didn't strictly ask for it, 
  // but Manage Users usually implies it. 
  // I'll skip delete action implementation details for now if the service doesn't have it, 
  // OR I can add deleteEmployee to EmployeeService given I am already modifying it?
  // I will check EmployeeService again. It does NOT have delete.
  // I will just show the list for now to satisfy "add user ... to admin panel"
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: EmployeeService.getAllEmployeesStream(),
              builder: (context, snapshot) {
                final employees = snapshot.data ?? [];
                final filteredEmployees = _filterEmployees(employees);
                final isLoading = snapshot.connectionState == ConnectionState.waiting && snapshot.data == null;

                return Column(
                  children: [
                    // Custom Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
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
                              icon: Icon(Icons.arrow_back_ios_new_rounded, 
                                color: AppTheme.textPrimary(context), size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Manage Users',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '${filteredEmployees.length}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor(context)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor(context),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: AppTheme.textPrimary(context)),
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            hintStyle: TextStyle(
                              color: AppTheme.textHint(context),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search_rounded, 
                              color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),

                    // Employees List
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                          : filteredEmployees.isEmpty
                              ? _buildEmptyState(context)
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                  itemCount: filteredEmployees.length,
                                  itemBuilder: (context, index) {
                                    final employee = filteredEmployees[index];
                                    return _buildEmployeeCard(context, employee, index);
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient(),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              AppTheme.slideRoute(const CreateUserScreen()),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Add User', 
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Map<String, dynamic> employee, int index) {
    final name = employee['name'] as String? ?? 'Unnamed';
    final companyId = employee['company_id'] as String?;
    final companyName = _companyNames[companyId] ?? 'Unknown Company';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    // Stagger animation
    final start = (index * 0.1).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.glassColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor(context),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppTheme.textPrimary(context),
              ),
            ),
            subtitle: Text(
              companyName,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppTheme.surfaceColor(context),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditEmployeeDialog(context, employee);
                } else if (value == 'delete') {
                  _showDeleteEmployeeDialog(context, employee);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: AppTheme.textPrimary(context)),
                      const SizedBox(width: 12),
                      Text('Edit', style: TextStyle(color: AppTheme.textPrimary(context))),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_rounded, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, 
              size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No users yet'
                : 'No matching users',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showEditEmployeeDialog(BuildContext context, Map<String, dynamic> employee) async {
    final nameController = TextEditingController(text: employee['name']);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Employee', style: TextStyle(color: AppTheme.textPrimary(context))),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            style: TextStyle(color: AppTheme.textPrimary(context)),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newName = nameController.text.trim();
                if (newName != employee['name']) {
                  final success = await EmployeeService.updateEmployee(
                    employee['id'],
                    name: newName,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Employee updated successfully'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Failed to update employee'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  }
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteEmployeeDialog(BuildContext context, Map<String, dynamic> employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete User?', style: TextStyle(color: AppTheme.textPrimary(context))),
        content: Text(
          'Are you sure you want to delete "${employee['name']}"? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary(context))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await EmployeeService.deleteEmployee(employee['id']);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User deleted successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete user'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }
}
