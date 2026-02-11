import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the brightness to choose the correct logo variant if needed,
    // but user requested "AppLogo.jpeg" specifically. 
    // If they wanted different logos for dark/light, we would use Theme.of(context).brightness.
    // For now, using the requested asset.
    
    return Scaffold(
      backgroundColor: Colors.white, // Or adapt to theme if needed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the requested logo
            Image.asset(
              'assets/images/AppLogo.jpeg',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // Optional: Loading indicator
            const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
