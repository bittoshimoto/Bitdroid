import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bit_wallet/providers/wallet_provider.dart';
import 'package:bit_wallet/providers/blockchain_provider.dart';
import 'package:bit_wallet/views/home/privacy_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeInAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteWallet(BuildContext context, WalletProvider wp, BlockchainProvider bp) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Warning', style: TextStyle(color: Colors.red, fontFamily: 'Ubuntu')),
          content: const Text(
            'Are you sure you want to delete your wallet? Make sure you have a backup of your private key.',
            style: TextStyle(color: Colors.white70, fontFamily: 'Ubuntu'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.blueAccent, fontFamily: 'Ubuntu')),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red, fontFamily: 'Ubuntu')),
              onPressed: () async {
                await wp.deleteWallet();
                bp.clearTransactions();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/setup', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Could not launch $url');
  }
}

  Widget _buildButton(String text, VoidCallback onPressed, {Color color = const Color(0xFFF7931A)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontFamily: 'Ubuntu', fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 5,
        ),
        onPressed: onPressed,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WalletProvider>(context);
    final bp = Provider.of<BlockchainProvider>(context);
    final privateKey = wp.privateKey ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kBottomNavigationBarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextField(
                    controller: TextEditingController(text: privateKey),
                    decoration: InputDecoration(
                      labelText: 'Private Key',
                      labelStyle: const TextStyle(color: Colors.orange),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.orange, width: 1.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.orange, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.orange, width: 1.0),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.copy, color: Colors.orange),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: privateKey));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Colors.green),
                          );
                        },
                      ),
                    ),
                    style: const TextStyle(color: Colors.orange),
                    obscureText: true,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your private key is critical.\nKeep it safe!\nAnyone with it can control your assets.',
                    style: TextStyle(color: Colors.red, fontFamily: 'Ubuntu', fontSize: 20,),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildButton('Privacy Policy', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyView()))),
                  _buildButton('Support', () => _launchURL('https://discord.gg/UevXymWWjD')),
                  _buildButton('About', () => _launchURL('https://followthebit.org')),
                  const SizedBox(height: 30),
                  _buildButton('Delete Wallet', () => _confirmDeleteWallet(context, wp, bp), color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
