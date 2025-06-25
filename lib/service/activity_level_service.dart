import 'dart:convert';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLevelService {
  static const String baseUrl = ApiConstants.baseUrl; // Ganti dengan URL API Anda
  
  // ✅ IMPROVED: Update activity level (1-4 scale) with better error handling
  static Future<Map<String, dynamic>> updateActivityLevel({
    required int activityLevel,
  }) async {
    try {
      print('🔄 Starting updateActivityLevel...');
      print('📊 Activity level to update: $activityLevel');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        print('❌ No authentication token found');
        return {
          'success': false,
          'message': 'No authentication token found. Please login again.',
        };
      }

      print('✅ Auth token found: ${token.substring(0, 20)}...');

      // Validasi activity level
      if (activityLevel < 1 || activityLevel > 4) {
        print('❌ Invalid activity level: $activityLevel');
        return {
          'success': false,
          'message': 'Invalid activity level. Must be between 1-4',
        };
      }

      final requestBody = {
        'activityLevel': activityLevel,
      };

      print('🔄 Request body: ${json.encode(requestBody)}');
      print('🔄 Making API call to: $baseUrl/user/updateData');

      final response = await http.put(
        Uri.parse('$baseUrl/user/updateData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30)); // Add timeout

      print('🔄 Response status code: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ API call successful');
        
        // ✅ IMPROVED: Update SharedPreferences dengan data baru
        await _updateLocalStorage(activityLevel);
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Activity level updated successfully',
          'data': responseData['user'],
        };
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['error'] ?? responseData['message'] ?? 'Failed to update activity level',
          'errors': responseData['errors'],
        };
      }
      
    } catch (e) {
      print('❌ Exception in updateActivityLevel: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ✅ IMPROVED: Helper function untuk update local storage dengan logging
  static Future<void> _updateLocalStorage(int activityLevel) async {
    try {
      print('🔄 Updating local storage...');
      final prefs = await SharedPreferences.getInstance();
      
      // Update global storage
      await prefs.setInt('activityLevel', activityLevel);
      print('✅ Global activityLevel updated: $activityLevel');
      
      // Update user-specific storage jika ada user ID
      final userId = prefs.getInt('id') ?? 0;
      if (userId > 0) {
        await prefs.setInt('activityLevel_$userId', activityLevel);
        print('✅ User-specific activityLevel_$userId updated: $activityLevel');
      } else {
        print('⚠️ No user ID found for user-specific storage');
      }

      // ✅ TAMBAHAN: Simpan activity level sebagai string juga untuk UI consistency
      final activityLevelString = getActivityLevelString(activityLevel);
      await prefs.setString('activityLevelName', activityLevelString);
      if (userId > 0) {
        await prefs.setString('activityLevelName_$userId', activityLevelString);
      }
      print('✅ Activity level string saved: $activityLevelString');

    } catch (e) {
      print('❌ Error updating local storage: $e');
    }
  }

  // Get current activity level from local storage
  static Future<int?> getCurrentActivityLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try user-specific first
      final userId = prefs.getInt('id') ?? 0;
      if (userId > 0) {
        final userSpecificLevel = prefs.getInt('activityLevel_$userId');
        if (userSpecificLevel != null) {
          print('📊 Found user-specific activity level: $userSpecificLevel');
          return userSpecificLevel;
        }
      }
      
      // Fallback to global
      final globalLevel = prefs.getInt('activityLevel');
      print('📊 Found global activity level: $globalLevel');
      return globalLevel;
    } catch (e) {
      print('❌ Error getting current activity level: $e');
      return null;
    }
  }

  // ✅ IMPROVED: Convert activity level number to string
  static String getActivityLevelString(int level) {
    switch (level) {
      case 1:
        return 'Not Very Active';
      case 2:
        return 'Lightly Active';
      case 3:
        return 'Active';
      case 4:
        return 'Very Active';
      default:
        return 'Unknown';
    }
  }

  // ✅ IMPROVED: Convert activity level string to number
  static int getActivityLevelNumber(String levelString) {
    switch (levelString) {
      case 'Not Very Active':
        return 1;
      case 'Lightly Active':
        return 2;
      case 'Active':
        return 3;
      case 'Very Active':
        return 4;
      default:
        print('⚠️ Unknown activity level string: $levelString');
        return 0;
    }
  }

  // ✅ IMPROVED: Get activity level with detailed info
  static Future<Map<String, dynamic>> getActivityLevelInfo() async {
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
        Uri.parse('$baseUrl/user/activityLevel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 15));

      print('🔄 Get activity level info - Status: ${response.statusCode}');
      print('🔄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get activity level info',
        };
      }
      
    } catch (e) {
      print('❌ Error getting activity level info: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Calculate BMR multiplier based on activity level
  static double getActivityMultiplier(int activityLevel) {
    switch (activityLevel) {
      case 1: // Not Very Active
        return 1.2;
      case 2: // Lightly Active
        return 1.375;
      case 3: // Active
        return 1.55;
      case 4: // Very Active
        return 1.725;
      default:
        return 1.2; // Default to sedentary
    }
  }

  // ✅ TAMBAHAN: Debug method untuk troubleshooting
  static Future<void> debugActivityLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id') ?? 0;
      
      print('=== ACTIVITY LEVEL DEBUG ===');
      print('User ID: $userId');
      print('Global activityLevel: ${prefs.getInt('activityLevel')}');
      print('User-specific activityLevel_$userId: ${prefs.getInt('activityLevel_$userId')}');
      print('Global activityLevelName: ${prefs.getString('activityLevelName')}');
      print('User-specific activityLevelName_$userId: ${prefs.getString('activityLevelName_$userId')}');
      print('Auth token exists: ${prefs.getString('auth_token') != null}');
      print('===========================');
    } catch (e) {
      print('❌ Error in debug: $e');
    }
  }
}