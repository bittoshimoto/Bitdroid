import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bit_wallet/config.dart';
import 'package:bit_wallet/services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final WalletService _ws = WalletService();

  final String rpcUrl = Config.rpcUrl;
  final String rpcUser = Config.rpcUser;
  final String rpcPassword = Config.rpcPassword;

  String? _privateKey;
  String? _address;
  double _balance = 0.0;
  List _utxos = [];
  List<Map<String, dynamic>> _selectedUtxos = [];

  String? get privateKey => _privateKey;
  String? get address => _address;
  double get balance => _balance;
  List get utxos => _utxos;

  WalletProvider() {
    loadWallet();
  }

  Future<void> loadWallet() async {
    _privateKey = await _storage.read(key: 'key');
    if (_privateKey != null) {
      _address = _ws.loadAddressFromKey(_privateKey!);
      await fetchUtxos();
    }
    notifyListeners();
  }

  Future<void> saveWallet(String address, String privateKey) async {
    _privateKey = privateKey;
    _address = address;
    await _storage.write(key: 'key', value: privateKey);
    await fetchUtxos();
    notifyListeners();
  }

  Future<void> deleteWallet() async {
    _privateKey = null;
    _address = null;
    _balance = 0.0;
    _utxos = [];
    await _storage.delete(key: 'key');
    notifyListeners();
  }

  Future<void> fetchUtxos() async {
    if (_address == null) return;

    try {
      final result = await _ws.rpcRequest('listunspent', [0, 9999999, [_address]]);

      if (result != null && result['result'] != null) {
        final utxos = result['result'] as List;
        _utxos = utxos;
        double total = 0.0;
        for (var utxo in utxos) {
          if ((utxo['spendable'] ?? false) == true) {
            total += utxo['amount'];
          }
        }
        _balance = double.parse(total.toStringAsFixed(8));
      } else {
        _balance = 0.0;
        _utxos = [];
      }
    } catch (e) {
      print('Fetch UTXOs error: $e');
      _balance = 0.0;
      _utxos = [];
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>?> createTransaction(String destinationAddress, double? amount) async {
    await fetchUtxos();

    List<Map<String, dynamic>> inputs = [];
    double accumulated = 0.0;
    _selectedUtxos.clear();

    for (var utxo in _utxos) {
      if ((utxo['spendable'] ?? false) == true) {
        inputs.add({
          'txid': utxo['txid'],
          'vout': utxo['vout'],
        });
        _selectedUtxos.add(utxo);
        accumulated += utxo['amount'];

        if (accumulated >= (amount ?? 0) + 0.0001) {
          break;
        }
      }
    }

    if (inputs.isEmpty) {
      throw Exception('No spendable UTXOs found.');
    }

    if (amount == null || amount > accumulated) {
      amount = accumulated;
    }

    double fee = 0.0025;
    if (accumulated < amount + fee) {
      throw Exception('Insufficient funds.');
    }

    double change = accumulated - amount - fee;
    amount = double.parse(amount.toStringAsFixed(8));
    change = double.parse(change.toStringAsFixed(8));

    final Map<String, dynamic> outputs = {
      destinationAddress: amount,
    };

    if (change > 0) {
      outputs[_address!] = change;
    }

    final createRawResult = await _ws.rpcRequest('createrawtransaction', [
      inputs,
      outputs
    ]);

    return createRawResult;
  }

  Future<Map<String, dynamic>> sendTransaction(String destinationAddress, double amount) async {
  if (_privateKey == null || _address == null) {
    return {'success': false, 'message': 'Private key or address is missing'};
  }

  final createRawResult = await createTransaction(destinationAddress, amount);
  if (createRawResult == null) {
    return {'success': false, 'message': 'Failed to create transaction'};
  }

  final rawTx = createRawResult['result'];

  // 📢 Use node's wallet to sign it
  final signRawResult = await _ws.rpcRequest('signrawtransaction', [rawTx]);

  if (signRawResult == null || signRawResult['result'] == null || !(signRawResult['result']['complete'] ?? false)) {
    return {'success': false, 'message': 'Failed to sign transaction'};
  }

  final signedTx = signRawResult['result']['hex'];

  final sendResult = await _ws.rpcRequest('sendrawtransaction', [signedTx]);

  if (sendResult == null || sendResult['result'] == null) {
    return {'success': false, 'message': 'Failed to broadcast transaction'};
  }

  return {'success': true, 'message': 'Transaction sent successfully'};
}
}