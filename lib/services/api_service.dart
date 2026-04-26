import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  final storage = const FlutterSecureStorage();

  String get baseUrl => AppConstants.baseUrl;

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.read(key: 'token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'User-Agent': 'LeoniMobileApp',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final contentType = response.headers['content-type'] ?? '';
    
    if (kDebugMode) {
      print('[API] Status: ${response.statusCode}');
      print('[API] Content-Type: $contentType');
      print('[API] Body: ${response.body}');
    }

    if (contentType.contains('text/html') || response.body.trim().startsWith('<!DOCTYPE html>') || response.body.trim().startsWith('<html')) {
      throw Exception('Backend connection error: Received HTML instead of JSON');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to parse JSON response: $e');
      }
    } else {
      String errorMessage = 'Request failed: ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'].toString();
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
             errorMessage += ' ${response.body}';
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> login(String matricule, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    if (kDebugMode) {
      print('Logging in to: $url');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'LeoniMobileApp',
        },
        body: jsonEncode({'matricule': matricule, 'password': password}),
      );

      final data = await _handleResponse(response);
      
      await storage.write(key: 'token', value: data['access_token']);
      await storage.write(key: 'user', value: jsonEncode(data['user']));
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Login Error: $e');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url, 
      headers: headers,
      body: jsonEncode(body)
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.patch(
      url, 
      headers: headers,
      body: jsonEncode(body)
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadFile(String endpoint, File file) async {
    final headers = await getHeaders();
    final url = Uri.parse('$baseUrl$endpoint');
    
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }
}
