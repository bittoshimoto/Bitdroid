import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening URLs

class ExchangeView extends StatelessWidget {
  const ExchangeView({super.key});

  // Function to launch URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.of(context).size.height - kBottomNavigationBarHeight,
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.black],
                stops: [0, 0.75],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 75, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'EXCHANGES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // List of exchange links
                  InkWell(
                    onTap: () {
                      _launchURL('https://app.exbitron.com/exchange/?market=B1T-USDT');
                    },
                    child: Text(
                      'Exbitron',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _launchURL('https://xeggex.com/market/B1T_USDT');
                    },
                    child: Text(
                      'XeggeX Exchange',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _launchURL('https://safetrade.com/exchange/B1T-USDT?type=basic');
                    },
                    child: Text(
                      'SafeTrade',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _launchURL('https://mecacex.com/market/B1TUSDT');
                    },
                    child: Text(
                      'Mecacex',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

