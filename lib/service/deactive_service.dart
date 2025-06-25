import 'dart:convert';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeactiveService {
  // Base URL - ganti dengan URL backend Anda
  static const String baseUrl = ApiConstants.baseUrl; // Ganti dengan base_url Anda
  
  /// Deactivate user account
  /// 
  /// [inputPassword] - Password yang diinput user untuk verifikasi
  /// Returns Map dengan struktur:
  /// - success: boolean
  /// - message: string
  /// - data: object (optional)
  static Future<Map<String, dynamic>> deactivateAccount(String inputPassword) async {
    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      final authToken = prefs.getString('auth_token');
      final userEmail = prefs.getString('email');
      
      // Debug: Print user data
      print('🔍 Debug User Data:');
      print('   User ID: $userId');
      print('   Email: $userEmail');
      print('   Auth Token: ${authToken?.substring(0, 10)}...');
      print('   Input Password Length: ${inputPassword.length}');
      
      // Validasi data yang diperlukan
      if (userId == null || authToken == null || authToken.isEmpty) {
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
        };
      }
      
      if (inputPassword.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Password is required for account deactivation.',
        };
      }
      
      // Validasi password format
      if (!isValidPassword(inputPassword)) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long.',
        };
      }
      
      print('🔄 Deactivating account with server-side password verification...');
      
      // Prepare request body dengan password untuk verifikasi di server
      final requestBody = {
        'user_id': userId,
        'email': userEmail,
        'password': inputPassword, // Kirim password untuk verifikasi di server
      };
      
      print('📤 Deactivate Request Body: ${json.encode(requestBody)}');
      
      // Make deactivation API request dengan password verification
      final response = await http.post(
        Uri.parse('$baseUrl/user/deactivateAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('📡 Deactivate API Response Status: ${response.statusCode}');
      print('📡 Deactivate API Response Body: ${response.body}');
      
      // Cek apakah response body valid JSON
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }
      
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
      
      // Handle different status codes
      switch (response.statusCode) {
        case 200:
          // Success
          if (responseData['success'] == true) {
            print('✅ Account deactivated successfully');
            
            // Clear all user data from SharedPreferences
            await _clearUserData();
            
            return {
              'success': true,
              'message': responseData['message'] ?? 'Account deactivated successfully',
              'data': responseData['data'],
            };
          } else {
            // API returned success: false
            print('❌ API returned success: false');
            return {
              'success': false,
              'message': responseData['message'] ?? 'Failed to deactivate account',
            };
          }
          
        case 400:
          // Bad Request - Invalid data
          print('❌ Bad Request (400): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Invalid request data',
          };
          
        case 401:
          // Unauthorized - Kemungkinan password salah
          print('❌ Unauthorized (401): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Incorrect password. Please check your password and try again.',
          };
          
        case 403:
          // Forbidden
          print('❌ Forbidden (403): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Access forbidden',
          };
          
        case 404:
          // Not Found - User not found
          print('❌ Not Found (404): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'User account not found',
          };
          
        case 422:
          // Unprocessable Entity - Validation errors (kemungkinan password salah)
          print('❌ Validation Error (422): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Incorrect password. Please check your password and try again.',
          };
          
        case 500:
          // Internal Server Error
          print('❌ Server Error (500): ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Server error. Please try again later.',
          };
          
        default:
          // Other status codes
          print('❌ Unexpected Status Code: ${response.statusCode}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Unexpected error occurred (Status: ${response.statusCode})',
          };
      }
      
    } on http.ClientException catch (e) {
      // Network/HTTP client error
      print('❌ HTTP Client Error: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      // JSON parsing error
      print('❌ JSON Parse Error: $e');
      return {
        'success': false,
        'message': 'Invalid response format from server.',
      };
    } catch (e) {
      // Generic error
      print('❌ Unexpected Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }
  
  /// Alternative method: Verify password first, then deactivate
  /// Jika backend Anda memiliki endpoint terpisah untuk verifikasi password
  static Future<Map<String, dynamic>> deactivateAccountWithSeparateVerification(String inputPassword) async {
    try {
      // Get user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id');
      final authToken = prefs.getString('auth_token');
      final userEmail = prefs.getString('email');
      
      // Debug: Print user data
      print('🔍 Debug User Data:');
      print('   User ID: $userId');
      print('   Email: $userEmail');
      print('   Auth Token: ${authToken?.substring(0, 10)}...');
      print('   Input Password Length: ${inputPassword.length}');
      
      // Validasi data yang diperlukan
      if (userId == null || authToken == null || authToken.isEmpty || userEmail == null) {
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
        };
      }
      
      if (inputPassword.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Password is required for account deactivation.',
        };
      }
      
      // Validasi password format
      if (!isValidPassword(inputPassword)) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters long.',
        };
      }
      
      print('🔄 Step 1: Verifying password with login endpoint...');
      
      // Step 1: Verify password menggunakan login endpoint
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': userEmail,
          'password': inputPassword,
        }),
      );
      
      print('📡 Login Verification Status: ${loginResponse.statusCode}');
      print('📡 Login Verification Body: ${loginResponse.body}');
      
      if (loginResponse.statusCode != 200) {
        Map<String, dynamic> loginData = {};
        try {
          loginData = json.decode(loginResponse.body);
        } catch (e) {
          // Ignore parsing error
        }
        
        return {
          'success': false,
          'message': loginData['message'] ?? 'Incorrect password. Please check your password and try again.',
        };
      }
      
      // Parse login response
      Map<String, dynamic> loginData;
      try {
        loginData = json.decode(loginResponse.body);
      } catch (e) {
        print('❌ JSON Parse Error for login: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
      
      // Check if login was successful
      if (loginData['success'] != true) {
        return {
          'success': false,
          'message': loginData['message'] ?? 'Incorrect password. Please check your password and try again.',
        };
      }
      
      print('✅ Password verified successfully');
      
      // Step 2: Deactivate account (tanpa kirim password karena sudah diverifikasi)
      print('🔄 Step 2: Deactivating account for user ID: $userId');
      
      final requestBody = {
        'user_id': userId,
        'email': userEmail,
        // Tidak perlu kirim password karena sudah diverifikasi
      };
      
      print('📤 Deactivate Request Body: ${json.encode(requestBody)}');
      
      // Make deactivation API request
      final response = await http.post(
        Uri.parse('$baseUrl/user/deactivateAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('📡 Deactivate API Response Status: ${response.statusCode}');
      print('📡 Deactivate API Response Body: ${response.body}');
      
      // Handle response sama seperti method utama
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }
      
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }
      
      // Handle success response
      if (response.statusCode == 200 && responseData['success'] == true) {
        print('✅ Account deactivated successfully');
        
        // Clear all user data from SharedPreferences
        await _clearUserData();
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Account deactivated successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to deactivate account',
        };
      }
      
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }
  
  /// Clear all user data from SharedPreferences
  static Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID before clearing (for logging)
      final userId = prefs.getInt('id') ?? 0;
      
      print('🧹 Clearing all user data for user ID: $userId');
      
      // Clear all data
      await prefs.clear();
      
      print('✅ All user data cleared successfully');
      
    } catch (e) {
      print('❌ Error clearing user data: $e');
      // Don't throw error, just log it
    }
  }
  
  /// Validate password format
  static bool isValidPassword(String password) {
    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) return false;
    if (trimmedPassword.length < 6) return false; // Minimum 6 characters
    
    // Tambahan validasi jika diperlukan
    // if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(trimmedPassword)) return false;
    
    return true;
  }
  
  /// Get current user info from SharedPreferences
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('id');
      final userEmail = prefs.getString('email');
      final userName = prefs.getString('full_name');
      final authToken = prefs.getString('auth_token');
      
      if (userId == null || authToken == null) {
        return null;
      }
      
      return {
        'id': userId,
        'email': userEmail ?? '',
        'name': userName ?? '',
        'has_auth_token': authToken.isNotEmpty,
      };
    } catch (e) {
      print('❌ Error getting user info: $e');
      return null;
    }
  }
  
  /// Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final authToken = prefs.getString('auth_token');
      
      return isLoggedIn && authToken != null && authToken.isNotEmpty;
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }
}