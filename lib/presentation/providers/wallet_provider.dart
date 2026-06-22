import 'package:flutter/material.dart';
import '../../data/models/wallet.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _repository = WalletRepository();

  Wallet? _wallet;
  bool _isLoading = false;
  String? _error;

  Wallet? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get savings => _wallet?.currentSavings ?? 0.0;

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _wallet = await _repository.getWallet();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSavings(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _wallet = await _repository.updateWallet(currentSavings: amount);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
