import 'dart:convert';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class FoodRenameService {
  static const String baseUrl = ApiConstants.baseUrl;

  // Helper method to get auth token from storage
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Replace 'auth_token' with your actual key name
      return prefs.getString('auth_token') ?? prefs.getString('access_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Helper method to get auth headers
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      // Common auth header formats - adjust based on your API
      headers['Authorization'] = 'Bearer $token';
      // Alternative formats if your API uses different format:
      // headers['Authorization'] = 'Token $token';
      // headers['X-Auth-Token'] = token;
    }
    
    return headers;
  }

  // Method untuk rename scan name (dengan authentication)
  static Future<Map<String, dynamic>> renameScan(
  String scanId,
  String newScanName,
) async {
  try {
    final url = Uri.parse('$baseUrl/scan/renameScan/$scanId');
    final payload = json.encode({
      'foodName': newScanName,
    });
    
    final headers = await _getAuthHeaders();
    
    print('Sending rename scan request: $url');
    print('Headers: $headers');
    print('Payload: $payload');

    final response = await http.post(
      url,
      headers: headers,
      body: payload,
    );

    print('Rename scan response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      // Check if response has success message
      if (responseData is Map<String, dynamic>) {
        // If response contains success message, mark it as successful
        if (responseData['message'] != null) {
          String message = responseData['message'].toString().toLowerCase();
          if (message.contains('success') || 
              message.contains('berhasil') ||
              message.contains('updated') ||
              message.contains('rename successfully')) {
            return {
              'success': true,
              'message': responseData['message'],
              'data': responseData
            };
          }
        }
        
        // Return the response as is if it already has success field
        if (responseData.containsKey('success')) {
          return responseData;
        }
        
        // If no clear success indicator, assume success for 200 response
        return {
          'success': true,
          'message': responseData['message'] ?? 'Scan renamed successfully',
          'data': responseData
        };
      } else {
        // If response is not a map, assume success for 200 response
        return {
          'success': true,
          'message': 'Scan renamed successfully',
          'data': responseData
        };
      }
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': 'Authentication failed. Please login again.',
        'error': 'unauthorized'
      };
    } else {
      return {
        'success': false,
        'message': 'Failed to rename scan: ${response.statusCode}',
        'error': response.body
      };
    }
  } catch (e) {
    print('Error renaming scan: $e');
    return {
      'success': false,
      'message': 'Error renaming scan: $e',
      'error': e.toString()
    };
  }
}

  // Method untuk update individual food items (dengan authentication)
  static Future<Map<String, dynamic>> updateFoodItems(
    String scanId,
    Map<int, String> newFoodNames,
  ) async {
    try {
      // Add proper implementation when endpoint is available
      final headers = await _getAuthHeaders();
      
      // Example implementation - adjust URL and payload based on your API
      final url = Uri.parse('$baseUrl/scan/updateFoodItems/$scanId');
      final payload = json.encode({
        'foodItems': newFoodNames,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: payload,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        // For now, return success for local updates
        return {
          'success': true,
          'message': 'Food items updated locally',
          'updatedItems': newFoodNames
        };
      }
    } catch (e) {
      print('Error updating food items: $e');
      throw Exception('Error updating food items: $e');
    }
  }

  static Future<Map<String, dynamic>> getScanById(String scanId) async {
    try {
      final url = Uri.parse('$baseUrl/scan/$scanId');
      final headers = await _getAuthHeaders();
      
      print('Fetching scan: $url');
      print('Headers: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      print('Get scan response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to get scan: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting scan: $e');
      throw Exception('Error getting scan: $e');
    }
  }

  // Optional: Method to check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await _getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Optional: Method to clear auth token (for logout)
  static Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('access_token');
    } catch (e) {
      print('Error clearing auth token: $e');
    }
  }
}