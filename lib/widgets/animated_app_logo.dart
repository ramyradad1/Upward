import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedAppLogo extends StatefulWidget {
  final double size;
  const AnimatedAppLogo({super.key, this.size = 150});

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();

    // Ripple Animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Breathing (Scale) Animation for the logo
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2, // Extra space for ripples
      height: widget.size * 2,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildRipple(0),
            _buildRipple(1),
            _buildRipple(2),
            _buildLogo(),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple(int index) {
    // Stagger the ripples
    final delay = index * 0.33; 
    
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        final value = (_rippleController.value + delay) % 1.0;
        final opacity = (1.0 - value).clamp(0.0, 1.0);
        final scale = 1.0 + (value * 1.5); // Grow significantly

        return Opacity(
          opacity: opacity * 0.4, // Max opacity 0.4
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  width: 2,
                ),
                color: AppTheme.primaryColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 10, // Reduced from 20
                    spreadRadius: 2, // Reduced from 5
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _breathingAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.4),
              blurRadius: 15, // Reduced from 30
              spreadRadius: 2, // Reduced from 5
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/AppLogo.jpeg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image not found
              return Container(
                color: AppTheme.primaryColor,
                child: const Icon(Icons.apps_rounded, size: 60, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}
