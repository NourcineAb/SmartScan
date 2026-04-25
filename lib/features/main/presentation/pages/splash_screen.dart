import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_scan/core/theme/app_colors.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

/// Animated splash screen with Lottie-style animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize controllers
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animations in sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();

    // Start text animation
    await _textController.forward();

    // Start pulsing effect
    _pulseController.repeat(reverse: true);

    // Wait for animations to complete then navigate
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      await _navigateBasedOnFirstLaunch();
    }
  }

  Future<void> _navigateBasedOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    if (!hasSeenWelcome) {
      // First launch - show welcome screen
      await prefs.setBool('has_seen_welcome', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } else {
      // Returning user - go to main screen
      _navigateToMainScreen();
    }
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo with scanning effect
            _buildAnimatedLogo(size),
            
            const SizedBox(height: 32),
            
            // Animated app name
            _buildAnimatedTitle(),
            
            const SizedBox(height: 16),
            
            // Animated tagline
            _buildAnimatedTagline(),
            
            const SizedBox(height: 48),
            
            // Loading indicator
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo(Size size) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final value = _logoController.value;
        
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4 * value),
                blurRadius: 20 * value,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Scan line animation
              Positioned(
                top: 20 + (value * 80),
                left: 20,
                right: 20,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Document icon
              Icon(
                Icons.document_scanner,
                size: 56,
                color: Colors.white.withOpacity(0.3 + (value * 0.7)),
              ),
              // Corner brackets
              ..._buildCornerBrackets(value),
            ],
          ),
        ).animate(controller: _logoController)
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          )
          .rotate(
            begin: -0.2,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          );
      },
    );
  }

  List<Widget> _buildCornerBrackets(double animationValue) {
    final bracketSize = 12.0;
    final opacity = animationValue;
    
    return [
      // Top-left
      Positioned(
        top: 16,
        left: 16,
        child: _buildCornerBracket(bracketSize, opacity, top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 16,
        right: 16,
        child: _buildCornerBracket(bracketSize, opacity, top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 16,
        left: 16,
        child: _buildCornerBracket(bracketSize, opacity, top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 16,
        right: 16,
        child: _buildCornerBracket(bracketSize, opacity, top: false, left: false),
      ),
    ];
  }

  Widget _buildCornerBracket(double size, double opacity, 
      {required bool top, required bool left}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: Colors.white.withOpacity(opacity), width: 2) 
              : BorderSide.none,
          bottom: !top ? BorderSide(color: Colors.white.withOpacity(opacity), width: 2) 
              : BorderSide.none,
          left: left ? BorderSide(color: Colors.white.withOpacity(opacity), width: 2) 
              : BorderSide.none,
          right: !left ? BorderSide(color: Colors.white.withOpacity(opacity), width: 2) 
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        final value = _textController.value;
        
        return Text(
          'SmartScan',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        )
          .animate(controller: _textController)
          .fadeIn(duration: 400.ms)
          .slideY(
            begin: 0.5,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOut,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 500.ms,
          );
      },
    );
  }

  Widget _buildAnimatedTagline() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Text(
          'Intelligent Document Scanning',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1,
          ),
        )
          .animate(controller: _textController)
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .slideY(
            begin: 0.3,
            end: 0,
            delay: 200.ms,
            duration: 400.ms,
          );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = _pulseController.value;
        
        return Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.2),
                AppColors.primary.withOpacity(0.3 + (value * 0.4)),
                AppColors.primary.withOpacity(0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
