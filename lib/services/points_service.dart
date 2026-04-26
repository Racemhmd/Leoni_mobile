import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class PointsService {
  final String baseUrl = AppConstants.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> getSummary() async {
    final token = await _storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/points/summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load points summary');
    }
  }

  Future<List<dynamic>> getHistory(String filter) async {
    final token = await _storage.read(key: 'auth_token');
    final response = await http.get(
      Uri.parse('$baseUrl/points/history?filter=$filter'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load points history');
    }
  }

  Future<void> redeemPoints(int points, String description) async {
    final token = await _storage.read(key: 'auth_token');
    final response = await http.post(
      Uri.parse('$baseUrl/points/xmall'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'points': points,
        'description': description,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to redeem points');
    }
  }
}
