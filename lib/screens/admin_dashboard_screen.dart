import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import 'login_screen.dart';
import 'create_user_screen.dart';
import 'manage_companies_screen.dart';
import 'manage_users_screen.dart';
import '../services/employee_service.dart';
import 'dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  
  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        AppTheme.slideRoute(const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? 'Admin';
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: Stack(
          children: [
            // Background Blobs
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(AppTheme.staggerAnimation(_entranceController, 0)),
                        child: FadeTransition(
                          opacity: AppTheme.staggerAnimation(_entranceController, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RepaintBoundary(
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/AppLogo.jpeg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Portal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary(context),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => _signOut(context),
                                icon: Icon(Icons.logout_rounded, 
                                  color: AppTheme.accentWarm),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.accentWarm.withValues(alpha: 0.1),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Admin Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(AppTheme.staggerAnimation(_entranceController, 1)),
                        child: FadeTransition(
                          opacity: AppTheme.staggerAnimation(_entranceController, 1),
                          child: RepaintBoundary(
                            child: Container(
                              padding: const EdgeInsets.all(24),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.admin_panel_settings_rounded,
                                        color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Super Administrator',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
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
                  ),

                  // Stats Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(AppTheme.staggerAnimation(_entranceController, 2)),
                        child: FadeTransition(
                          opacity: AppTheme.staggerAnimation(_entranceController, 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: CompanyService.getCompaniesStream(),
                                  initialData: CompanyService.currentCompanies,
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.length ?? 0;
                                    final isLoading = snapshot.connectionState == ConnectionState.waiting && snapshot.data == null;
                                    
                                    return _StatCard(
                                      icon: Icons.business_rounded,
                                      label: 'Companies',
                                      value: isLoading ? '...' : '$count',
                                      color: AppTheme.primaryColor,
                                    );
                                  }
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: EmployeeService.getAllEmployeesStream(),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.length ?? 0;
                                    final isLoading = snapshot.connectionState == ConnectionState.waiting && snapshot.data == null;
                                    
                                    return _StatCard(
                                      icon: Icons.people_outline_rounded,
                                      label: 'Users',
                                      value: isLoading ? '...' : '$count',
                                      color: AppTheme.accentColor,
                                    );
                                  }
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Actions Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: FadeTransition(
                        opacity: AppTheme.staggerAnimation(_entranceController, 3),
                        child: Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Cards List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildAnimatedActionCard(
                          4,
                          icon: Icons.business_rounded,
                          title: 'Manage Companies',
                          subtitle: 'View, create and edit companies',
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            AppTheme.slideRoute(const ManageCompaniesScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnimatedActionCard(
                          5,
                          icon: Icons.people_alt_rounded,
                          title: 'Manage Users',
                          subtitle: 'View and manage employees',
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            AppTheme.slideRoute(const ManageUsersScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnimatedActionCard(
                          6,
                          icon: Icons.person_add_rounded,
                          title: 'Create User',
                          subtitle: 'Add new admin or employee',
                          color: Colors.purple,
                          onTap: () => Navigator.push(
                            context,
                            AppTheme.slideRoute(const CreateUserScreen()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildAnimatedActionCard(
                          7,
                          icon: Icons.inventory_2_rounded,
                          title: 'Asset Dashboard',
                          subtitle: 'Go to main asset view',
                          color: Colors.teal,
                          onTap: () => Navigator.pushReplacement(
                            context,
                            AppTheme.slideRoute(const DashboardScreen()),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedActionCard(
    int index, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.2, 0),
        end: Offset.zero,
      ).animate(AppTheme.staggerAnimation(_entranceController, index)),
      child: FadeTransition(
        opacity: AppTheme.staggerAnimation(_entranceController, index),
        child: RepaintBoundary(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.glassColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.shadowColor(context),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, 
                      color: AppTheme.iconColor(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Try to parse value as int for animation
    final intValue = int.tryParse(value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          intValue != null 
              ? KeyedSubtree(
                  key: ValueKey(intValue),
                  child: _CountUp(
                    end: intValue,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountUp extends StatefulWidget {
  final int end;
  final TextStyle? style;

  const _CountUp({
    required this.end,
    this.style,
  });

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animation = IntTween(begin: 0, end: widget.end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _CountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end) {
      _controller.reset();
      _animation = IntTween(begin: 0, end: widget.end).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _animation.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}
