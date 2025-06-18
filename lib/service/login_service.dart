import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String loginEndpoint = '/auth/login';
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl$loginEndpoint');
      
      print('🔍 === LOGIN REQUEST DEBUG ===');
      print('🔍 URL: $url');
      print('🔍 Email: $email');
      print('🔍 Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('🔍 === API RESPONSE DEBUG ===');
      print('🔍 Status Code: ${response.statusCode}');
      print('🔍 Headers: ${response.headers}');
      print('🔍 Raw Body: ${response.body}');
      print('🔍 Body Length: ${response.body.length}');

      // Cek apakah response body kosong
      if (response.body.isEmpty) {
        print('❌ Empty response body');
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      late Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
        print('🔍 Parsed Response: $responseData');
        print('🔍 Response Type: ${responseData.runtimeType}');
        print('🔍 Response Keys: ${responseData.keys.toList()}');
      } catch (jsonError) {
        print('❌ JSON Parse Error: $jsonError');
        return {
          'success': false,
          'message': 'Invalid JSON response: $jsonError',
        };
      }

      // Debug setiap field yang penting
      print('🔍 === FIELD ANALYSIS ===');
      responseData.forEach((key, value) {
        print('🔍 $key: $value (${value.runtimeType})');
      });

      if (response.statusCode == 200) {
        print('🔍 === RESPONSE STRUCTURE ANALYSIS ===');
        
        // Log the complete structure
        if (responseData.containsKey('data')) {
          print('🔍 Data object found: ${responseData['data']}');
          if (responseData['data'] is Map && responseData['data']['user'] != null) {
            print('🔍 User object in data: ${responseData['data']['user']}');
            if (responseData['data']['user']['id'] != null) {
              print('🔍 User ID in data.user: ${responseData['data']['user']['id']}');
            }
          }
        }

        // Return the original response structure - let the UI handle extraction
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'data': responseData['data'], // Keep the original data structure
        };
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed with status ${response.statusCode}',
          'status_code': response.statusCode,
        };
      }
    } catch (e, stackTrace) {
      print('❌ Login service error: $e');
      print('❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error_type': e.runtimeType.toString(),
      };
    }
  }
}