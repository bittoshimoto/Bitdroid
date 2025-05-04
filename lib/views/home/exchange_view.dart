import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExchangeView extends StatefulWidget {
  const ExchangeView({super.key});

  @override
  State<ExchangeView> createState() => _ExchangeViewState();
}

class _ExchangeViewState extends State<ExchangeView> with SingleTickerProviderStateMixin {
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

  Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  )) {
    throw Exception('Could not launch $url');
  }
}

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Ubuntu',
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLinkButton(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7931A),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(fontFamily: 'Ubuntu', fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 5,
        ),
        onPressed: () => _launchURL(url),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('WEBSITE'),
                _buildLinkButton('Visit Website', 'https://followthebit.org'),

                _buildSectionTitle('EXPLORER'),
                _buildLinkButton('Blockchain Explorer', 'https://b1texplorer.com/'),

                _buildSectionTitle('EXCHANGES'),
                _buildLinkButton('Exbitron', 'https://app.exbitron.com/exchange/?market=B1T-USDT'),
                _buildLinkButton('XeggeX Exchange', 'https://xeggex.com/market/B1T_USDT'),
                _buildLinkButton('SafeTrade', 'https://safetrade.com/exchange/B1T-USDT?type=basic'),
                _buildLinkButton('Mecacex', 'https://mecacex.com/market/B1TUSDT'),

                _buildSectionTitle('SOCIALS'),
                _buildLinkButton('Discord', 'https://discord.gg/UevXymWWjD'),
                _buildLinkButton('Telegram', 'https://t.me/Bittoshimoto'),
                _buildLinkButton('Twitter / X', 'https://x.com/bittoshimo'),
                _buildLinkButton('GitHub', 'https://github.com/bittoshimoto'),
                _buildLinkButton('Reddit', 'https://www.reddit.com/r/FollowTheBit/'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
