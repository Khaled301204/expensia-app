import '../models/category.dart';
import '../services/api_service.dart';
import '../../core/config/app_config.dart';

class CategoryRepository {
  final ApiService _apiService = ApiService();

  static List<Category>? _cached;

  Future<List<Category>> getCategories() async {
    if (_cached != null) return _cached!;
    try {
      final response = await _apiService.get(AppConfig.categoriesEndpoint);
      final body = response.data;
      List raw;
      if (body is Map && body['success'] == true) {
        raw = body['data'] as List;
      } else if (body is List) {
        raw = body;
      } else {
        return _fallback();
      }
      _cached = raw.map((j) => Category.fromJson(j)).toList();
      return _cached!;
    } catch (_) {
      return _fallback();
    }
  }

  List<Category> _fallback() => [
        Category(id: 1, name: 'Food & Dining'),
        Category(id: 2, name: 'Transportation'),
        Category(id: 3, name: 'Shopping'),
        Category(id: 4, name: 'Entertainment'),
        Category(id: 5, name: 'Bills & Utilities'),
        Category(id: 6, name: 'Healthcare'),
        Category(id: 7, name: 'Education'),
        Category(id: 8, name: 'Travel'),
        Category(id: 9, name: 'Personal Care'),
        Category(id: 10, name: 'Other'),
      ];
}
