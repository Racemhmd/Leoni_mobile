import 'api_service.dart';

class SanctionsService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getSanctionStats({
    required String period,
    String? type,
  }) async {
    String endpoint = '/sanctions/stats?period=$period';
    if (type != null && type.isNotEmpty && type != 'All') {
      endpoint += '&type=$type';
    }

    try {
      final response = await _apiService.get(endpoint);
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load sanction stats: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSanctionDetails({
    required String period,
    String? type,
  }) async {
    String endpoint = '/sanctions/details?period=$period';
    if (type != null && type.isNotEmpty && type != 'All') {
      endpoint += '&type=$type';
    }

    try {
      final response = await _apiService.get(endpoint);
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load sanction details: $e');
    }
  }
}
