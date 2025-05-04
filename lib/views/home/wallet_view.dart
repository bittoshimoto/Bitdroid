import 'package:bit_wallet/widgets/transaction_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bit_wallet/providers/blockchain_provider.dart';
import 'package:bit_wallet/providers/wallet_provider.dart';
import 'package:bit_wallet/views/home/receive_view.dart';
import 'package:bit_wallet/views/home/send_view.dart';
import 'package:bit_wallet/widgets/button_widget.dart';
import 'package:bit_wallet/modals/transaction_modal.dart';
import 'package:bit_wallet/views/home/transactions_view.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> with SingleTickerProviderStateMixin {
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

  Future<void> _onRefresh() async {
    final wp = Provider.of<WalletProvider>(context, listen: false);
    final bp = Provider.of<BlockchainProvider>(context, listen: false);
    await bp.loadBlockchain(wp.address);
  }

  void _showTransactionDetails(String txid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TransactionModal(txid: txid),
    );
  }

  List<FlSpot> _generateLineData(List<dynamic> transactions) {
    final reversed = transactions.reversed.toList();
    return List.generate(reversed.length, (index) {
      double balance = double.tryParse(reversed[index]['balance'].toString()) ?? 0;
      return FlSpot(index.toDouble(), balance);
    });
  }

  double _getMaxY(List<FlSpot> spots) {
    final maxY = spots.map((e) => e.y).fold(0.0, (prev, curr) => curr > prev ? curr : prev);
    return maxY == 0 ? 1 : maxY * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final blockchainProvider = Provider.of<BlockchainProvider>(context);
    final String timestamp = blockchainProvider.timestamp;
    final List<dynamic> transactions = blockchainProvider.transactions;
    final double? balance = transactions.isNotEmpty ? transactions[0]['balance'].toDouble() : 0.0;
    final double price = blockchainProvider.price;
    final String? balanceInUSD = balance != null ? (balance * price).toStringAsFixed(2) : null;
    final List<FlSpot> chartSpots = _generateLineData(transactions);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        backgroundColor: Colors.black,
        color: Color(0xFFF7931A),
        onRefresh: _onRefresh,
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kBottomNavigationBarHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    if (blockchainProvider.isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFFF7931A)),
                      )
                    else ...[
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            balanceInUSD != null ? '\$$balanceInUSD' : '-',
                            style: const TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Color(0xFFF7931A),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 260),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Image.asset('assets/blaccck.png'),
                                ),
                              ),
                              Text(
                                balance != null ? balance.toStringAsFixed(8) : '0.00000000',
                                style: const TextStyle(
                                  fontFamily: 'Ubuntu',
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
Container(
  width: double.infinity,
  height: 300,
  decoration: BoxDecoration(
    color: Colors.black,
    border: Border.all(color: Color(0xFFF7931A), width: 2),
    borderRadius: BorderRadius.zero,
  ),
  child: LineChart(
    LineChartData(
  clipData: FlClipData(
    top: true,
    bottom: false, // allow curve to bend below
    left: true,
    right: true,
  ),

  extraLinesData: ExtraLinesData(), // fine to leave empty for now

  lineTouchData: LineTouchData(enabled: false),

  gridData: FlGridData(
    show: false,
    drawVerticalLine: true,
    horizontalInterval: 1,
    verticalInterval: 1,
    getDrawingHorizontalLine: (value) => FlLine(
      color: Color(0xFF3E3E3E),
      strokeWidth: 1,
    ),
    getDrawingVerticalLine: (value) => FlLine(
      color: Color(0xFF3E3E3E),
      strokeWidth: 1,
    ),
  ),

  titlesData: FlTitlesData(show: false),
  borderData: FlBorderData(
    show: true,
    border: Border.all(color: Color(0xFFF7931A), width: 2),
  ),

  minX: 0,
  maxX: chartSpots.length > 1 ? (chartSpots.length - 1).toDouble() : 1,
  minY: -0.5, // <--- allow space below
  maxY: _getMaxY(chartSpots),

  lineBarsData: [
    LineChartBarData(
      spots: chartSpots,
      isCurved: false,
      gradient: LinearGradient(
        colors: [Color(0xFFF7931A), Color(0xFFFFA726)],
      ),
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7931A).withOpacity(0.3),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),
  ],
),
  ),
),
                          const SizedBox(height: 20),
                          Text(
                            'Synchronized: $timestamp',
                            style: const TextStyle(
                              fontFamily: 'Ubuntu',
                              color: Colors.grey,
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF7931A),
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontFamily: 'Ubuntu', fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 5,
                            ),
                            icon: const Icon(Icons.arrow_upward),
                            label: const Text('Send'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SendView()),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF7931A),
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontFamily: 'Ubuntu', fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 5,
                            ),
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('Receive'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ReceiveView()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (transactions.isEmpty)
                        const Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(fontFamily: 'Ubuntu', color: Colors.white, fontSize: 16),
                          ),
                        )
                      else ...[
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontFamily: 'Ubuntu',
                            color: Color(0xFFF7931A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...transactions.take(5).map((tx) => TransactionTile(
                              tx: tx,
                              onTap: () => _showTransactionDetails(tx['txid']),
                            )),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(color: Color(0xFFF7931A), width: 2),
                              foregroundColor: Color(0xFFF7931A),
                              textStyle: const TextStyle(fontFamily: 'Ubuntu', fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Show All'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TransactionsView()),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}