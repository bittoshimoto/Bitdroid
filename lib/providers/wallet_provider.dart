import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bit_wallet/config.dart';
import 'package:bit_wallet/services/wallet_service.dart';
import 'dart:async';

class WalletProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final WalletService _ws = WalletService();

  final String rpcUrl = Config.rpcUrl;
  final String rpcUser = Config.rpcUser;
  final String rpcPassword = Config.rpcPassword;

  String? _privateKey;
  String? _address;
  double? _balance = 0.0;
  List _utxos = [];
  Timer? _balanceRefreshTimer;

  String? get privateKey => _privateKey;
  String? get address => _address;
  double? get balance => _balance;
  List? get utxos => _utxos;

  WalletProvider() {
    loadWallet();
  }

  Future<void> loadWallet() async {
    _privateKey = await _storage.read(key: 'key');
    if (_privateKey != null) {
      _address = _ws.loadAddressFromKey(_privateKey!);
      await fetchUtxos();
      _startAutoBalanceRefresh();
    }
    notifyListeners();
  }

  void _startAutoBalanceRefresh() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = Timer.periodic(Duration(minutes: 10), (_) async {
      await fetchUtxos();
    });
  }

  Future<void> saveWallet(String address, String privateKey) async {
    _privateKey = privateKey;
    _address = address;
    await _storage.write(key: 'key', value: privateKey);
    await fetchUtxos();
    _startAutoBalanceRefresh();
    notifyListeners();
  }

  Future<void> deleteWallet() async {
    _privateKey = null;
    _address = null;
    _balanceRefreshTimer?.cancel();
    await _storage.delete(key: 'key');
    notifyListeners();
  }

  Future<void> fetchUtxos() async {
    if (_address == null) return;

    await _ws.rpcRequest('importaddress', [_address, '', false]);
    final result = await _ws.rpcRequest('listunspent', []);

    if (result != null && result['result'] != null) {
      final allUtxos = result['result'] as List;
      final utxos = allUtxos.where((utxo) => utxo['address'] == _address).toList();

      for (var utxo in utxos) {
        final txid = utxo['txid'];
        final rawTxResult = await _ws.rpcRequest('getrawtransaction', [txid, true]);

        if (rawTxResult != null &&
            rawTxResult['result'] != null &&
            rawTxResult['result']['vout'] != null) {
          final vout = rawTxResult['result']['vout'] as List;
          final matchingVout = vout.firstWhere(
            (v) => v['n'] == utxo['vout'],
            orElse: () => null,
          );
          if (matchingVout != null &&
              matchingVout['scriptPubKey'] != null &&
              matchingVout['scriptPubKey']['hex'] != null) {
            utxo['scriptPubKey'] = matchingVout['scriptPubKey']['hex'];
          }
        }
      }

      _utxos = utxos;

      double totalBalance = 0.0;
      for (var utxo in utxos) {
        totalBalance += utxo['amount'];
      }
      _balance = totalBalance;
    }

    notifyListeners();
  }

  double getMaxSendableAmount() {
    const double fee = 0.0025;
    if (_balance != null && _balance! > fee) {
      return double.parse((_balance! - fee).toStringAsFixed(8));
    }
    return 0.0;
  }

  Future<Map<String, dynamic>?> createTransaction(String toAddress, double? amount, List<Map<String, dynamic>> usedUtxosOut) async {
    await fetchUtxos();

    const double fee = 0.0025;
    List<Map<String, dynamic>> inputs = [];
    double accumulatedAmount = 0.0;

    for (var utxo in _utxos) {
      inputs.add({
        'txid': utxo['txid'],
        'vout': utxo['vout'],
      });
      usedUtxosOut.add(utxo);
      accumulatedAmount += utxo['amount'];
    }

    if (amount == null || amount >= accumulatedAmount) {
      amount = accumulatedAmount;
    }

    if (amount == accumulatedAmount) {
      if (accumulatedAmount <= fee) {
        throw Exception('Insufficient funds to cover the fee');
      }
      amount -= fee;
    } else {
      if (accumulatedAmount < amount + fee) {
        throw Exception('Insufficient UTXOs to cover the amount and the fee');
      }
    }

    double change = accumulatedAmount - amount - fee;
    amount = double.parse(amount.toStringAsFixed(8));
    change = double.parse(change.toStringAsFixed(8));

    Map<String, dynamic> outputs = { toAddress: amount };
    if (change > 0) {
      outputs[_address!] = change;
    }

    final createRawResult = await _ws.rpcRequest('createrawtransaction', [inputs, outputs]);
    return createRawResult;
  }

  Future<Map<String, dynamic>> sendTransaction(String toAddress, double amount) async {
    if (_privateKey == null || _address == null) {
      return {'success': false, 'message': 'Private key or address is missing'};
    }

    List<Map<String, dynamic>> usedUtxos = [];
    final createRawResult = await createTransaction(toAddress, amount, usedUtxos);
    if (createRawResult == null) {
      return {'success': false, 'message': 'Error creating raw transaction'};
    }

    final rawTx = createRawResult['result'];

    final prevTxs = usedUtxos.map((utxo) => {
      'txid': utxo['txid'],
      'vout': utxo['vout'],
      'scriptPubKey': utxo['scriptPubKey'],
      'amount': utxo['amount']
    }).toList();

    final signRawResult = await _ws.rpcRequest('signrawtransaction', [
      rawTx,
      prevTxs,
      [_privateKey]
    ]);

    if (signRawResult == null || signRawResult['result'] == null || !signRawResult['result']['complete']) {
      return {'success': false, 'message': 'Transaction is not fully signed'};
    }

    final signedTx = signRawResult['result']['hex'];
    final sendRawResult = await _ws.rpcRequest('sendrawtransaction', [signedTx]);

    if (sendRawResult == null || sendRawResult['result'] == null) {
      return {'success': false, 'message': 'Error sending transaction'};
    }

    await Future.delayed(Duration(seconds: 3));
    await fetchUtxos();

    return {
      'success': true,
      'message': 'Transaction sent successfully',
      'txid': sendRawResult['result']
    };
  }
}
