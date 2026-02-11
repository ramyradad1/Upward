import 'package:flutter/material.dart';
import '../services/company_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController, 
      curve: Curves.easeOut
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1), 
      end: Offset.zero
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a company name', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final id = await CompanyService.createCompany(name);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (id != null) {
        _showSnack('Company created successfully!');
        Navigator.pop(context);
      } else {
        _showSnack('Failed to create company', isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.accentWarm : AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
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
                        'New Company',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient(),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.business_rounded, 
                                    color: Colors.white, size: 40),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Text(
                                  'Register Company',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Add a new entity to the system',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Form Card
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.borderColor(context)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.shadowColor(context),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    CustomTextField(
                                      label: 'Company Name',
                                      placeholder: 'Enter official name',
                                      icon: Icons.business_center_outlined,
                                      controller: _nameController,
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _createCompany,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
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
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Create Company',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Icon(Icons.check_circle_outline_rounded, size: 20),
                                                ],
                                              ),
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
