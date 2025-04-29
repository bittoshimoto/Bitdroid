import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bit_wallet/providers/wallet_provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _logoAnimation = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textAnimation = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
  _logoController.forward();
  await Future.delayed(const Duration(seconds: 2));
  _textController.forward();
  await Future.delayed(const Duration(seconds: 2));
  await Future.delayed(const Duration(seconds: 2)); // <-- ADD THIS EXTRA WAIT

  final wp = Provider.of<WalletProvider>(context, listen: false);
  if (wp.privateKey != null) {
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    Navigator.pushReplacementNamed(context, '/setup');
  }
}
  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoAnimation,
              child: SizedBox(
                width: 400,
                height: 400,
                child: Image.asset('assets/blaccck.png'), // <-- use your logo asset here
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _textAnimation,
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 40, fontFamily: 'Ubuntu'),
                      children: [
                        const TextSpan(text: 'Follow The ', style: TextStyle(color: Colors.white)),
                        const TextSpan(text: 'Bit', style: TextStyle(color: Color(0xFFF7931A))),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 34, fontFamily: 'Ubuntu'),
                      children: [
                        const TextSpan(text: 'Become ', style: TextStyle(color: Color(0xFFF7931A))),
                        const TextSpan(text: 'the movement', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
