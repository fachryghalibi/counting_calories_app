import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk register, login, logout, dan test connection
class RegisterService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  /// Register user
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? dateOfBirth, // OPTIONAL kalau backend perlu
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/register');
      print('🔵 Attempting to register to: $url');

      final body = {
        'email': email,
        'password': password,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };
      print('🔵 Register Body: $body');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Register Status: ${response.statusCode}');
      print('🔵 Register Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'data': data,
        };
      } else {
        return _handleErrorResponse(data, response.statusCode, 'Registration failed');
      }
    } catch (e) {
      return _handleException(e, 'register');
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      print('🔵 Attempting to login to: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Login Status: ${response.statusCode}');
      print('🔵 Login Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server returned empty response',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'data': data,
          'token': data['token'],
        };
      } else {
        return _handleErrorResponse(data, response.statusCode, 'Login failed');
      }
    } catch (e) {
      return _handleException(e, 'login');
    }
  }

  /// Logout user
  static Future<Map<String, dynamic>> logout(String token) async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      print('🔵 Attempting to logout to: $url');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('🔵 Logout Status: ${response.statusCode}');
      print('🔵 Logout Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Logout successful',
        };
      } else {
        return _handleErrorResponse(data, response.statusCode, 'Logout failed');
      }
    } catch (e) {
      return _handleException(e, 'logout');
    }
  }

  /// Test connection ke server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final url = Uri.parse('$baseUrl');
      print('🔵 Testing connection to: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      print('🔵 Test Status: ${response.statusCode}');
      print('🔵 Test Body: ${response.body}');

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'message': response.statusCode >= 200 && response.statusCode < 300
            ? 'Connection successful'
            : 'Server returned status ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server: ${e.toString()}',
      };
    }
  }

  /// Helper untuk error response
  static Map<String, dynamic> _handleErrorResponse(
    Map<String, dynamic> data,
    int statusCode,
    String fallbackMessage,
  ) {
    String errorMessage = fallbackMessage;

    if (data.containsKey('message')) {
      errorMessage = data['message'];
    } else if (data.containsKey('error')) {
      errorMessage = data['error'];
    }

    // Handle validation errors
    if (data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is List) {
        if (errors.isNotEmpty) {
          errorMessage = errors.join(', ');
        }
      } else if (errors is Map) {
        final errorMessages = <String>[];
        errors.forEach((key, value) {
          if (value is List) {
            errorMessages.addAll(value.map((e) => e.toString()));
          } else {
            errorMessages.add(value.toString());
          }
        });
        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join(', ');
        }
      }
    }

    return {
      'success': false,
      'message': errorMessage,
      'status_code': statusCode,
      'errors': data['errors'],
      'raw_data': data,
    };
  }

  /// Helper untuk exception
  static Map<String, dynamic> _handleException(Object e, String context) {
    print('❌ $context exception: $e');
    return {
      'success': false,
      'message': 'Error: ${e.toString()}',
    };
  }
}
