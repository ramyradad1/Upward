import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../services/company_service.dart';
import '../services/auth_service.dart';

import '../l10n/app_localizations.dart';
import 'hover_scale.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _itemAnimation(int index) {
    final start = (index * 0.1).clamp(0.0, 0.7);
    final end = (start + 0.3).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Drawer(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Fixed at top
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, 0),
                  end: Offset.zero,
                ).animate(_itemAnimation(0)),
                child: FadeTransition(
                  opacity: _itemAnimation(0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient(),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/AppLogo.jpeg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)?.appTitle ?? 'Upward',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: AppTheme.dividerColor(context)),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Home
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(1)),
                      child: FadeTransition(
                        opacity: _itemAnimation(1),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/dashboard');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.borderColor(context),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.dashboard_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Home',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.iconColor(context),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Assets
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(1)),
                      child: FadeTransition(
                        opacity: _itemAnimation(1),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/assets');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppTheme.borderColor(context),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Assets',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppTheme.iconColor(context),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Theme Toggle
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(1)),
                      child: FadeTransition(
                        opacity: _itemAnimation(1),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                themeProvider.toggleTheme();
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: AppTheme.animNormal,
                                      transitionBuilder: (child, anim) =>
                                          RotationTransition(
                                        turns: Tween(begin: 0.5, end: 1.0)
                                            .animate(anim),
                                        child: FadeTransition(
                                            opacity: anim, child: child),
                                      ),
                                      child: Icon(
                                        themeProvider.themeIcon,
                                        key: ValueKey(themeProvider.themeMode),
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${AppLocalizations.of(context)!.theme}: ${themeProvider.themeMode == ThemeMode.light ? AppLocalizations.of(context)!.themeLight : themeProvider.themeMode == ThemeMode.dark ? AppLocalizations.of(context)!.themeDark : AppLocalizations.of(context)!.themeSystem}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Language Toggle
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(2)),
                      child: FadeTransition(
                        opacity: _itemAnimation(2),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                final newLocale = themeProvider.locale.languageCode == 'en'
                                    ? const Locale('ar')
                                    : const Locale('en');
                                themeProvider.setLocale(newLocale);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        themeProvider.locale.languageCode == 'en' ? 'EN' : 'ع',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        themeProvider.locale.languageCode == 'en' ? 'Language: English' : 'اللغة: العربية',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.translate_rounded,
                                        color: AppTheme.iconColor(context), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Locations
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(3)),
                      child: FadeTransition(
                        opacity: _itemAnimation(3),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/locations');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Locations',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Licenses
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(3)),
                      child: FadeTransition(
                        opacity: _itemAnimation(3),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/licenses');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.card_membership_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Licenses',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Audit
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(4)),
                      child: FadeTransition(
                        opacity: _itemAnimation(4),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/audit');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.fact_check_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Audit',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Map View
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(5)),
                      child: FadeTransition(
                        opacity: _itemAnimation(5),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/map');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.map_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Asset Map',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Requests
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(6)),
                      child: FadeTransition(
                        opacity: _itemAnimation(6),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/requests');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.assignment_turned_in_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Requests',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // My Custody
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(7)),
                      child: FadeTransition(
                        opacity: _itemAnimation(7),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/my_custody');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'My Custody',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Analytics
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(8)),
                      child: FadeTransition(
                        opacity: _itemAnimation(8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/analytics');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.analytics_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Analytics',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Asset Handover
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(9)),
                      child: FadeTransition(
                        opacity: _itemAnimation(9),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                if (Scaffold.of(context).hasDrawer &&
                                    Scaffold.of(context).isDrawerOpen) {
                                  Navigator.pop(context);
                                }
                                context.go('/handover');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Asset Handover',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Maintenance (Phase 6)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(9)),
                      child: FadeTransition(
                        opacity: _itemAnimation(9),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/maintenance');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.build_circle_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Maintenance',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // QR Scanner
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(10)),
                      child: FadeTransition(
                        opacity: _itemAnimation(10),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: HoverScale(
                              onTap: () {
                                context.pop();
                                context.push('/qr_scanner');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.borderColor(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'QR Scanner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: AppTheme.iconColor(context), size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(3)),
                      child: FadeTransition(
                        opacity: _itemAnimation(3),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                          child: Text(
                            AppLocalizations.of(context)!.companies.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textHint(context),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Company List - Now in scrollable area
                    SizedBox(
                      height: 400, // Fixed height for company list
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: CompanyService.getCompaniesStream(),
                        initialData: CompanyService.currentCompanies,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            );
                          }
                          final companies = snapshot.data ?? [];
                          if (companies.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.business_outlined,
                                      size: 40,
                                      color: AppTheme.textHint(context)),
                                  const SizedBox(height: 8),
                                  Text(AppLocalizations.of(context)!.noCompanies,
                                      style: TextStyle(
                                          color: AppTheme.textHint(context))),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: companies.length,
                            itemBuilder: (context, index) {
                              final company = companies[index];
                              final anim = _itemAnimation(index + 4);
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(-0.3, 0),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: FadeTransition(
                                  opacity: anim,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        tileColor: AppTheme.glassColor(context),
                                        leading: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.business_rounded,
                                              color: AppTheme.primaryColor,
                                              size: 18),
                                        ),
                                        title: Text(
                                          company['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Divider(color: AppTheme.dividerColor(context)),
                    ),
                    
                          // Logout Button
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-0.3, 0),
                        end: Offset.zero,
                      ).animate(_itemAnimation(6)),
                      child: FadeTransition(
                        opacity: _itemAnimation(6),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await AuthService.signOut();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentWarm.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppTheme.accentWarm.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentWarm.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.logout_rounded,
                                          color: AppTheme.accentWarm, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.logout,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.accentWarm,
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
