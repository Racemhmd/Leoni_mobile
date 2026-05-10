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

  Future<List<Map<String, dynamic>>> getEmployeeHistory(String matricule) async {
    try {
      final response = await _apiService.get('/sanctions/employee/$matricule');
      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load employee sanction history: $e');
    }
  }

  Future<Map<String, dynamic>> getKpiDashboardData({String period = '6', String? matricule, String? group}) async {
    try {
      String query = '?period=$period';
      if (matricule != null && matricule.isNotEmpty) {
        query += '&matricule=$matricule';
      }
      if (group != null && group.isNotEmpty) {
        query += '&group=$group';
      }
      final response = await _apiService.get('/sanctions/kpi-dashboard$query');
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return {'totals': {}, 'chartData': []};
    } catch (e) {
      throw Exception('Failed to load kpi dashboard data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getKpiByGroupData({String period = '6', String? group}) async {
    try {
      String query = '?period=$period';
      if (group != null && group.isNotEmpty) {
        query += '&group=$group';
      }
      final response = await _apiService.get('/sanctions/kpi/group$query');
      if (response != null && response is List) {
        return List<Map<String, dynamic>>.from(response);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load kpi group data: $e');
    }
  }

  Future<Map<String, dynamic>> getKpiByEmployeeData(String matricule, {String period = '6'}) async {
    try {
      final response = await _apiService.get('/sanctions/kpi/employee/$matricule?period=$period');
      if (response != null && response is Map<String, dynamic>) {
        return response;
      }
      return {'employee': {}, 'totals': {}, 'timeBasedData': []};
    } catch (e) {
      throw Exception('Failed to load employee kpi data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllEmployees() async {
    try {
      final response = await _apiService.get('/users');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    }
  }
}
