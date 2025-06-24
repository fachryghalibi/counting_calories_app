import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Ganti dengan URL API Anda
  
  // Update user data (email, username, etc.)
  static Future<Map<String, dynamic>> updateUserData({
    String? username,
    String? email,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    int? activityLevel,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      // Build request body with only non-null values
      Map<String, dynamic> requestBody = {};
      
      if (username != null && username.trim().isNotEmpty) {
        requestBody['username'] = username.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        requestBody['email'] = email.trim();
      }
      if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty) {
        requestBody['dateOfBirth'] = dateOfBirth.trim();
      }
      if (gender != null && gender.trim().isNotEmpty) {
        requestBody['gender'] = gender.trim();
      }
      if (height != null) {
        requestBody['height'] = height;
      }
      if (weight != null) {
        requestBody['weight'] = weight;
      }
      if (activityLevel != null) {
        requestBody['activityLevel'] = activityLevel;
      }

      print('🔄 Updating user data with: $requestBody');

      final response = await http.put(
        Uri.parse('$baseUrl/user/updateData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update local storage with new data
        if (username != null && username.trim().isNotEmpty) {
          await prefs.setString('username', username.trim());
        }
        if (email != null && email.trim().isNotEmpty) {
          await prefs.setString('email', email.trim());
        }
        if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty) {
          await prefs.setString('dateOfBirth', dateOfBirth.trim());
        }
        if (gender != null && gender.trim().isNotEmpty) {
          await prefs.setString('gender', gender.trim());
        }
        if (height != null) {
          await prefs.setDouble('height', height);
        }
        if (weight != null) {
          await prefs.setDouble('weight', weight);
        }
        if (activityLevel != null) {
          await prefs.setInt('activityLevel', activityLevel);
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'data': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('❌ Error updating user data: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Update password
  static Future<Map<String, dynamic>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      if (oldPassword.trim().isEmpty) {
        return {
          'success': false,
          'message': 'Current password is required',
        };
      }

      if (newPassword.trim().length < 6) {
        return {
          'success': false,
          'message': 'New password must be at least 6 characters long',
        };
      }

      final requestBody = {
        'oldPassword': oldPassword.trim(),
        'newPassword': newPassword.trim(),
      };

      print('🔄 Updating password...');

      final response = await http.post(
        Uri.parse('$baseUrl/user/updatePassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📡 Password update response status: ${response.statusCode}');
      print('📡 Password update response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? responseData['message'] ?? 'Failed to update password',
        };
      }
    } catch (e) {
      print('❌ Error updating password: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/currentUser'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 30));

      print('📡 Get current user response status: ${response.statusCode}');
      print('📡 Get current user response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {
          'success': true,
          'data': userData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      print('❌ Error getting current user: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }

  // Validation methods
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidUsername(String username) {
    return username.length >= 3 && username.length <= 50;
  }

  static bool isValidHeight(double height) {
    return height >= 1.0 && height <= 500.0;
  }

  static bool isValidWeight(double weight) {
    return weight >= 1.0 && weight <= 500.0;
  }

  static bool isValidActivityLevel(int activityLevel) {
    return activityLevel >= 1 && activityLevel <= 4;
  }
}