import 'package:flutter/material.dart';

import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<_Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Pulse animation for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Generate random bubbles
    for (int i = 0; i < 15; i++) {
      _bubbles.add(
        _Bubble(
          left: _random.nextDouble(),
          top: _random.nextDouble(),
          size: _random.nextDouble() * 80 + 20,
          speed: _random.nextDouble() * 0.5 + 0.2,
          color: Color.fromRGBO(
            _random.nextInt(100) + 155, // Light/Pastel colors
            _random.nextInt(100) + 155,
            255,
            _random.nextDouble() * 0.2 + 0.1,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slight off-white/bluish tint
      body: Stack(
        children: [
          // Floating Bubbles Background
          ..._bubbles.map((bubble) => _AnimatedBubble(bubble: bubble)),

          // Centered Pulsing Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/AppLogo.jpeg', // Using requested asset
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  final double left; // 0.0 to 1.0
  final double top; // 0.0 to 1.0
  final double size;
  final double speed;
  final Color color;

  _Bubble({
    required this.left,
    required this.top,
    required this.size,
    required this.speed,
    required this.color,
  });
}

class _AnimatedBubble extends StatefulWidget {
  final _Bubble bubble;

  const _AnimatedBubble({required this.bubble});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Random duration based on speed
    final duration = Duration(
      milliseconds: (3000 / widget.bubble.speed).round(),
    );
    _controller = AnimationController(vsync: this, duration: duration)
      ..repeat(reverse: true);

    // Bubble floats slightly up and down
    _animation = Tween<double>(begin: -20.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: widget.bubble.left * size.width,
      top: widget.bubble.top * size.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: Container(
              width: widget.bubble.size,
              height: widget.bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.bubble.color.withValues(alpha: 0.4),
                    widget.bubble.color.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
