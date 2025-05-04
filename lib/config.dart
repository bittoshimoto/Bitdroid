class Config {
  static const String addressPrefix = 'B';  // Just for info
  static const int networkPrefix = 0x9E;    // Private key WIF prefix
  static const int pubkeyHashPrefix = 0x19; // 25 decimal for addresses starting with 'B'

  static const String rpcUrl = 'http://';
  static const String rpcUser = '';
  static const String rpcPassword = '';

  static const String explorerUrl =
      '';
  static const String getAddressTxsEndpoint = '/ext/getaddresstxs';
  static const String getTxEndpoint = '/ext/gettx';

  static const String priceUrl = '';
}
