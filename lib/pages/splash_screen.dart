import 'package:flutter/material.dart';
import 'landing_page.dart'; // Update the import path if needed

class SplashScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userType;

  const SplashScreen({super.key, this.userData, this.userType});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutBack,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _textController.forward();
    });

    // Navigate after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LandingPage(
            userData: widget.userData,
            userType: widget.userType,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _iconAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Image.asset(
                    'images/launcher_icon01.png', // <-- Correct path
                    width: 64,
                    height: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _textAnimation,
                child: Text(
                  'WILD STEPS',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: const Color(0xFF4CAF50),
                    fontFamily: 'Montserrat', // Use a modern font if available
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}