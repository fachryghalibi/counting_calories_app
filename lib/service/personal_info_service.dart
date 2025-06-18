import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PersonalInfoService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Ganti dengan URL API Anda
  
  // Update personal info (username, dateOfBirth, gender)
  static Future<Map<String, dynamic>> updatePersonalInfo({
    String? username,
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
          'message': 'No authentication token found',
        };
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {};
      
      if (username != null && username.trim().isNotEmpty) {
        requestBody['username'] = username.trim();
      }
      
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        requestBody['dateOfBirth'] = dateOfBirth;
      }
      
      if (gender != null && gender.isNotEmpty) {
        requestBody['gender'] = gender;
      }
      
      if (height != null && height > 0) {
        requestBody['height'] = height;
      }
      
      if (weight != null && weight > 0) {
        requestBody['weight'] = weight;
      }
      
      if (activityLevel != null && activityLevel >= 1 && activityLevel <= 4) {
        requestBody['activityLevel'] = activityLevel;
      }

      if (requestBody.isEmpty) {
        return {
          'success': false,
          'message': 'No data to update',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/user/updateData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update SharedPreferences dengan data baru
        await _updateLocalStorage(requestBody);
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Personal info updated successfully',
          'data': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Failed to update personal info',
          'errors': responseData['errors'],
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Setup account pertama kali (jika user belum setup)
  static Future<Map<String, dynamic>> setupAccount({
    required String username,
    required String gender,
    required double height,
    required double weight,
    required int activityLevel,
    required DateTime dateOfBirth,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final requestBody = {
        'username': username.trim(),
        'gender': gender,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/user/setupAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Update SharedPreferences dengan data baru
        await _updateLocalStorage({
          'username': username,
          'gender': gender,
          'height': height,
          'weight': weight,
          'activityLevel': activityLevel,
          'dateOfBirth': dateOfBirth.toIso8601String(),
        });
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Account setup successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to setup account',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Helper function untuk update local storage
  static Future<void> _updateLocalStorage(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (data.containsKey('username')) {
      await prefs.setString('username', data['username']);
    }
    
    if (data.containsKey('gender')) {
      await prefs.setString('gender', data['gender']);
    }
    
    if (data.containsKey('height')) {
      await prefs.setDouble('height', data['height'].toDouble());
    }
    
    if (data.containsKey('weight')) {
      await prefs.setDouble('weight', data['weight'].toDouble());
    }
    
    if (data.containsKey('activityLevel')) {
      await prefs.setInt('activityLevel', data['activityLevel']);
    }
    
    if (data.containsKey('dateOfBirth')) {
      await prefs.setString('dateOfBirth', data['dateOfBirth']);
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
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/currentUser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return {
          'success': true,
          'data': userData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get user data',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Format date untuk backend (YYYY-MM-DD)
  static String formatDateForBackend(int day, int month, int year) {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  // Format date dari backend ke DateTime
  static DateTime? parseDateFromBackend(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
}