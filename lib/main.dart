import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bit_wallet/providers/wallet_provider.dart';
import 'package:bit_wallet/providers/blockchain_provider.dart';
import 'package:bit_wallet/views/setup_view.dart';
import 'package:bit_wallet/views/home_view.dart';
import 'package:bit_wallet/views/home/splash_view.dart'; // <--- ADD THIS LINE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final wp = WalletProvider();
  final bp = BlockchainProvider();
  await wp.loadWallet();
  if (wp.address != null) {
    bp.loadBlockchain(wp.address);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WalletProvider>.value(value: wp),
        ChangeNotifierProvider<BlockchainProvider>.value(value: bp),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',  // <-- Always start from splash
      routes: {
        '/': (context) => const SplashView(),  // <-- Default Splash Screen
        '/setup': (context) => SetupView(),
        '/home': (context) => const HomeView(),
      },
    );
  }
}
