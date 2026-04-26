import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SanctionsService {
  static const String baseUrl = 'http://localhost:3000/sanctions'; // Adjust as needed
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getSanctionStats({
    required String period,
    String? type,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('No token found');

    var uri = Uri.parse('$baseUrl/stats?period=$period');
    if (type != null && type.isNotEmpty && type != 'All') {
      uri = Uri.parse('$baseUrl/stats?period=$period&type=$type');
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load sanction stats: ${response.body}');
    }
  }
}
