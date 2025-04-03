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

class _WalletViewState extends State<WalletView> {
  Future<void> _onRefresh() async {
    final wp = Provider.of<WalletProvider>(context, listen: false);
    final bp = Provider.of<BlockchainProvider>(context, listen: false);
    await bp.loadBlockchain(wp.address);
  }

  void _showTransactionDetails(String txid) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TransactionModal(txid: txid),
    );
  }

  List<FlSpot> _generateDataPoints(List<dynamic> transactions) {
    final reversedTransactions = transactions.reversed.toList();
    if (reversedTransactions.isEmpty) {
      return [
        const FlSpot(0.0, 0.0),
        const FlSpot(1.0, 0.0),
      ];
    }

    return [
      const FlSpot(0.0, 0.0),
      ...reversedTransactions.asMap().entries.map((entry) {
        final index = entry.key;
        final transaction = entry.value;
        return FlSpot(
          (index + 1).toDouble(),
          double.parse(transaction['balance'].toString()),
        );
      }),
    ];
  }

  LineChartData _buildChartData(List<dynamic> transactions, double? balance) {
  if (transactions.isEmpty || balance == null) {
    print("DEBUG: No transactions or balance is null");
    return LineChartData(
      borderData: FlBorderData(show: false),
      backgroundColor: Colors.transparent,
      minX: 0.0,
      maxX: 1.0,
      minY: 0.0,
      maxY: 1.0,
      lineBarsData: [],
    );
  }

  final double maxX = transactions.length.toDouble();

  // Extract amounts safely
  List<double> amounts = transactions
      .map((t) => (t['amount'] as num?)?.toDouble() ?? 0.0)
      .toList();

  if (amounts.isEmpty) {
    print("DEBUG: No valid amounts found in transactions");
    return LineChartData(
      borderData: FlBorderData(show: false),
      backgroundColor: Colors.transparent,
      minX: 0.0,
      maxX: 1.0,
      minY: 0.0,
      maxY: 1.0,
      lineBarsData: [],
    );
  }

  // Find the highest transaction ever
  final double highestTransaction = amounts.reduce((a, b) => a > b ? a : b);

  // 🔥 **Dynamic Scaling Factor** 🔥
  // Ensures the chart always fits in the same visible area
  final double scaleFactor = highestTransaction > 0 ? highestTransaction / 10 : 1.0;

  // Apply scaling to maxY
  double maxY = highestTransaction > 0 ? highestTransaction / scaleFactor : balance * 1.1;
  maxY = maxY.clamp(1.0, 10.0); // Keep it within a readable range

  // Adjust minY to keep smaller transactions visible
  double minY = amounts.reduce((a, b) => a < b ? a : b) / scaleFactor;
  minY = minY.clamp(0.0, maxY * 0.1);

  print("DEBUG: maxX=$maxX, maxY=$maxY, minY=$minY, scaleFactor=$scaleFactor");

  return LineChartData(
    borderData: FlBorderData(show: false),
    backgroundColor: Colors.transparent,
    minX: 0.0,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
    lineBarsData: [
      LineChartBarData(
        spots: _generateDataPoints(transactions).map((point) =>
          FlSpot(point.x, point.y / scaleFactor) // 🔥 Apply Scaling 🔥
        ).toList(),
        isCurved: false,
        color: Color(0xFFF7931A),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.black.withOpacity(0.2),
        ),
      ),
    ],
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final blockchainProvider = Provider.of<BlockchainProvider>(context);

    // Extrahiere die relevanten Daten aus dem Provider
    final String timestamp = blockchainProvider.timestamp;
    final List<dynamic> transactions = blockchainProvider.transactions;
    final double? balance =
        transactions.isNotEmpty ? transactions[0]['balance'].toDouble() : 0.0;
    final double price = blockchainProvider.price;
    final String? balanceInUSD =
        balance != null ? (balance * price).toStringAsFixed(2) : null;

    return Scaffold(
      body: RefreshIndicator(
        backgroundColor: const Color.fromARGB(255, 25, 25, 25),
        color: Colors.orangeAccent,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Ermöglicht das Ziehen, auch wenn der Inhalt nicht scrollt
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kBottomNavigationBarHeight,
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9933), Colors.black],
                  stops: [0, 0.75],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 50, bottom: 20),
                child: Column(
                  children: [
                    if (blockchainProvider.isLoading)
                      const SizedBox(
                        height: 100,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Colors.white,
                        )),
                      )
                    else ...[
                      // Balance-Anzeige
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            balanceInUSD != null ? '\$$balanceInUSD' : '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            balance != null ? '$balance' : '-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'B1T',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          // Diagramm
                          SizedBox(
                            height: 250,
                            child: LineChart(
                                _buildChartData(transactions, balance)),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Synchronized: $timestamp',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      // Buttons: Send and Receive
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ButtonWidget(
                              text: 'Send',
                              isPrimary: true,
                              icon: Icons.arrow_upward,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const SendView()),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            ButtonWidget(
                              text: 'Receive',
                              isPrimary: true,
                              icon: Icons.arrow_downward,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ReceiveView()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Transaktionsliste
                      Column(
                        children: [
                          if (transactions.isEmpty)
                            const SizedBox(
                              height: 100,
                              child: Center(
                                child: Text(
                                  'No transactions found',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          if (transactions.isNotEmpty)
                            const Text('Recent transactions',
                                style: TextStyle(color: Colors.white)),
                          ...transactions.take(5).map((tx) => TransactionTile(
                                tx: tx,
                                onTap: () =>
                                    _showTransactionDetails(tx['txid']),
                              )),
                          if (transactions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ButtonWidget(
                                text: 'Show all',
                                isPrimary: true,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TransactionsView()),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
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
