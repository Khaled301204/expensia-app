import '../models/wallet.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class WalletRepository {
  final ApiService _apiService = ApiService();

  Future<Wallet> getWallet() async {
    final response = await _apiService.get(AppConfig.walletEndpoint);
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    return Wallet.fromJson(data as Map<String, dynamic>);
  }

  Future<Wallet> updateWallet({required double currentSavings}) async {
    final response = await _apiService.put(
      AppConfig.walletEndpoint,
      data: {'currentSavings': currentSavings},
    );
    final body = response.data;
    final data = (body is Map && body['success'] == true) ? body['data'] : body;
    return Wallet.fromJson(data as Map<String, dynamic>);
  }
}
