import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/company_service.dart';
import '../services/employee_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen>
    with SingleTickerProviderStateMixin {
  // Common
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Standard User Name Fields
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _familyNameController = TextEditingController();

  // Admin User Name Field
  final _adminNameController = TextEditingController();

  // Admin Access Flags
  bool _appAccess = false;
  bool _adminPanelAccess = false;

  String? _selectedCompanyId;
  String _selectedRole = 'user';

  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = false;
  bool _isFetchingCompanies = true;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
    _fetchCompanies();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _middleNameController.dispose();
    _familyNameController.dispose();
    _adminNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    final companies = await CompanyService.getCompanies();
    if (mounted) {
      setState(() {
        _companies = companies;
        _isFetchingCompanies = false;
        if (companies.isNotEmpty) {
          _selectedCompanyId = companies.first['id'];
        }
      });
    }
  }

  Future<void> _createUser() async {
    if (_selectedCompanyId == null) {
      _showSnack('Please select a company', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'user') {
        if (_firstNameController.text.isEmpty ||
            _secondNameController.text.isEmpty ||
            _middleNameController.text.isEmpty ||
            _familyNameController.text.isEmpty) {
          _showSnack('Please fill all name fields', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final fullName =
            '${_firstNameController.text.trim()} ${_secondNameController.text.trim()} ${_middleNameController.text.trim()} ${_familyNameController.text.trim()}';

        await EmployeeService.createEmployee(fullName,
            companyId: _selectedCompanyId);

        if (mounted) {
          _showSnack('Employee created successfully!');
          Navigator.pop(context);
        }
      } else {
        if (_emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _adminNameController.text.isEmpty) {
          _showSnack('Please fill name, email and password', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userId = authResponse.user?.id;

        if (userId != null) {
          await ProfileService.createProfile(
            userId: userId,
            email: _emailController.text.trim(),
            companyId: _selectedCompanyId!,
            role: _selectedRole,
            name: _adminNameController.text.trim(),
            appAccess: _appAccess,
            adminPanelAccess: _adminPanelAccess,
          );

          if (mounted) {
            _showSnack('Admin created successfully!');
            Navigator.pop(context);
          }
        } else {
          throw Exception('Auth creation failed');
        }
      }
    } on AuthException catch (e) {
      _showSnack('Auth Error: ${e.message}', isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.accentWarm : AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isStandardUser = _selectedRole == 'user';
    final roleColor =
        isStandardUser ? AppTheme.primaryColor : Colors.deepPurple;
    // final isDark = AppTheme.isDark(context);

    // Staggered animations
    final headerAnim = AppTheme.staggerAnimation(_animController, 0);
    final section1Anim = AppTheme.staggerAnimation(_animController, 1);
    final section2Anim = AppTheme.staggerAnimation(_animController, 2);
    final section3Anim = AppTheme.staggerAnimation(_animController, 3);
    final btnAnim = AppTheme.staggerAnimation(_animController, 4);

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
            child: Column(
              children: [
                // Header
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2), 
                    end: Offset.zero
                  ).animate(headerAnim),
                  child: FadeTransition(
                    opacity: headerAnim,
                    child: Padding(
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
                            'Add User',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: roleColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isStandardUser ? Icons.person_rounded : Icons.shield_rounded,
                                  size: 14,
                                  color: roleColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isStandardUser ? 'Employee' : 'Admin',
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
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

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Organization & Role Section
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section1Anim),
                          child: FadeTransition(
                            opacity: section1Anim,
                            child: _buildSectionCard(
                              icon: Icons.business_rounded,
                              title: 'Organization & Role',
                              color: AppTheme.primaryColor,
                              children: [
                                _buildDropdownLabel(context, 'Company'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFill(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.inputBorder(context)),
                                  ),
                                  child: _isFetchingCompanies
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SizedBox(
                                              height: 20, width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                        )
                                      : DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedCompanyId,
                                            isExpanded: true,
                                            hint: Text('Select Company', style: TextStyle(color: AppTheme.textHint(context))),
                                            dropdownColor: AppTheme.cardColor(context),
                                            borderRadius: BorderRadius.circular(16),
                                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                            style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                            items: _companies.map((company) {
                                              return DropdownMenuItem<String>(
                                                value: company['id'] as String,
                                                child: Text(company['name'] as String),
                                              );
                                            }).toList(),
                                            onChanged: (value) =>
                                                setState(() => _selectedCompanyId = value),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 20),
                                _buildDropdownLabel(context, 'Role'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.inputFill(context),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.inputBorder(context)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRole,
                                      isExpanded: true,
                                      borderRadius: BorderRadius.circular(16),
                                      dropdownColor: AppTheme.cardColor(context),
                                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.iconColor(context)),
                                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 15),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'user',
                                          child: Row(children: [
                                            Icon(Icons.person_outline_rounded, size: 18, color: AppTheme.primaryColor),
                                            SizedBox(width: 8),
                                            Text('Standard User (Employee)'),
                                          ]),
                                        ),
                                        DropdownMenuItem(
                                          value: 'admin',
                                          child: Row(children: [
                                            Icon(Icons.shield_outlined, size: 18, color: Colors.deepPurple),
                                            SizedBox(width: 8),
                                            Text('Company Admin'),
                                          ]),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedRole = value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Standard User Form
                        if (isStandardUser)
                          SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section2Anim),
                            child: FadeTransition(
                              opacity: section2Anim,
                              child: _buildSectionCard(
                                icon: Icons.person_rounded,
                                title: 'Employee Details',
                                color: AppTheme.primaryColor,
                                children: [
                                  CustomTextField(
                                    label: 'First Name',
                                    placeholder: 'e.g. Ahmed',
                                    icon: Icons.person,
                                    controller: _firstNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Second Name',
                                    placeholder: 'e.g. Mohamed',
                                    icon: Icons.person_outline,
                                    controller: _secondNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Middle Name',
                                    placeholder: 'e.g. Ali',
                                    icon: Icons.person_outline,
                                    controller: _middleNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Family Name',
                                    placeholder: 'e.g. Sayed',
                                    icon: Icons.groups_outlined,
                                    controller: _familyNameController,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Admin User Form
                        if (!isStandardUser) ...[
                          SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section2Anim),
                            child: FadeTransition(
                              opacity: section2Anim,
                              child: _buildSectionCard(
                                icon: Icons.badge_rounded,
                                title: 'Admin Credentials',
                                color: Colors.deepPurple,
                                children: [
                                  CustomTextField(
                                    label: 'Full Name',
                                    placeholder: 'e.g. Admin Name',
                                    icon: Icons.badge_outlined,
                                    controller: _adminNameController,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Email',
                                    placeholder: 'admin@company.com',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    label: 'Password',
                                    placeholder: 'Set password',
                                    icon: Icons.lock_outline_rounded,
                                    isPassword: true,
                                    controller: _passwordController,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(section3Anim),
                            child: FadeTransition(
                              opacity: section3Anim,
                              child: _buildSectionCard(
                                icon: Icons.security_rounded,
                                title: 'Access Control',
                                color: Colors.deepPurple,
                                children: [
                                  _buildAccessToggle(
                                    context,
                                    icon: Icons.phone_android_rounded,
                                    label: 'Mobile App Access',
                                    value: _appAccess,
                                    onChanged: (val) =>
                                        setState(() => _appAccess = val),
                                    activeColor: Colors.deepPurple,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildAccessToggle(
                                    context,
                                    icon: Icons.admin_panel_settings_outlined,
                                    label: 'Admin Panel Access',
                                    value: _adminPanelAccess,
                                    onChanged: (val) =>
                                        setState(() => _adminPanelAccess = val),
                                    activeColor: Colors.deepPurple,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit Button
                        SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(btnAnim),
                          child: FadeTransition(
                            opacity: btnAnim,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _createUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: roleColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      roleColor.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  shadowColor: roleColor.withValues(alpha: 0.3),
                                ).copyWith(
                                  elevation: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.pressed)) return 2;
                                    return 8;
                                  }),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isStandardUser
                                                ? Icons.person_add_rounded
                                                : Icons.admin_panel_settings_rounded,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isStandardUser
                                                ? 'Create Employee'
                                                : 'Create Admin',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
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
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAccessToggle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withValues(alpha: 0.08)
            : AppTheme.inputFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : AppTheme.inputBorder(context),
        ),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              icon,
              color: value ? activeColor : AppTheme.iconColor(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: value ? activeColor : AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppTheme.textSecondary(context),
        ),
      ),
    );
  }
}
