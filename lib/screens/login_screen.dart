import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/responsive_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../l10n/app_localizations.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Animations
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Faster entrance
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _entranceController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _logoController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted && response.session != null) {
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (e) {
      if (mounted) _showSnack('An unexpected error occurred', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.accentWarm : AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isDesktop =
        ResponsiveLayout.isDesktop(context) ||
        ResponsiveLayout.isTablet(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left Panel: Branding & Animations
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.backgroundGradient(context),
                    ),
                  ),
                  RepaintBoundary(child: _AnimatedBackground(isDark: isDark)),
                  // Branding Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _logoScale,
                          child: AnimatedBuilder(
                            animation: _breathingController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale:
                                    1.0 + (_breathingController.value * 0.05),
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF1E1E2C)
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(40),
                                  child: ClipOval(
                                    child: Image.asset(
                                      isDark
                                          ? 'assets/images/WhiteLogo.png'
                                          : 'assets/images/BlackLogo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.loginSubtitle,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Right Panel: Login Form
            Expanded(
              flex: 1,
              child: Container(
                color: isDark ? AppTheme.surfaceColor(context) : Colors.white,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(48),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to continue.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Form Container (Reused style or simplified for split screen)
                          // For split screen, we might not need the glass container, just the fields.
                          CustomTextField(
                            label: AppLocalizations.of(context)!.emailLabel,
                            placeholder: 'name@company.com',
                            icon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: AppLocalizations.of(context)!.passwordLabel,
                            placeholder: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.loginButton,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              'v1.1.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(
                                  context,
                                ).withValues(alpha: 0.5),
                              ),
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
      );
    }

    // Mobile Layout (Existing)
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          
          // Animated Background Blobs
          RepaintBoundary(child: _AnimatedBackground(isDark: isDark)),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated Logo
                          ScaleTransition(
                            scale: _logoScale,
                            child: AnimatedBuilder(
                              animation: _breathingController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: 1.0 + (_breathingController.value * 0.05),
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                          blurRadius: 40,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 10),
                                        ),
                                        BoxShadow(
                                          color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(40), // More breathing room
                                    child: ClipOval(
                                      child: Image.asset(
                                        isDark
                                            ? 'assets/images/WhiteLogo.png'
                                            : 'assets/images/BlackLogo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            AppLocalizations.of(context)!.appTitle,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.loginSubtitle,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v1.1.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Form Container
                          Container(
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
                              children: [
                                CustomTextField(
                                  label: AppLocalizations.of(context)!.emailLabel,
                                  placeholder: 'name@company.com',
                                  icon: Icons.email_outlined,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  label: AppLocalizations.of(context)!.passwordLabel,
                                  placeholder: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  controller: _passwordController,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 30),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                                    ).copyWith(
                                          elevation:
                                              WidgetStateProperty.resolveWith((
                                                states,
                                              ) {
                                                if (states.contains(
                                                  WidgetState.pressed,
                                                )) {
                                                  return 2;
                                                }
                                        return 8;
                                      }),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : _Shimmer(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  AppLocalizations.of(context)!.loginButton,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward_rounded, size: 20),
                                              ],
                                            ),
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
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  final bool isDark;
  const _AnimatedBackground({required this.isDark});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (_controller.value * 20),
              right: -100 - (_controller.value * 20),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: widget.isDark ? 0.1 : 0.15),
                      AppTheme.primaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 - (_controller.value * 30),
              left: -50 + (_controller.value * 20),
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: widget.isDark ? 0.05 : 0.1),
                      AppTheme.accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white,
                Colors.white.withValues(alpha: 0.7),
                Colors.white,
              ],
              stops: const [0.45, 0.5, 0.55],
              begin: Alignment(-1.0 + (2.0 * _controller.value), -0.5),
              end: Alignment(1.0 + (2.0 * _controller.value), 0.5),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
