import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BodyMeasurementsService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Helper method untuk mendapatkan token
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Helper method untuk headers dengan authorization
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Update body measurements (height dan weight saja sesuai database)
  static Future<Map<String, dynamic>> updateBodyMeasurements({
    required double height,
    required String heightUnit,
    required double weight,
    required String weightUnit,
  }) async {
    try {
      // Validasi input
      if (height <= 0) {
        return {
          'success': false,
          'message': 'Please enter a valid height',
        };
      }
      
      if (weight <= 0) {
        return {
          'success': false,
          'message': 'Please enter a valid current weight',
        };
      }

      // Konversi ke unit standar (cm dan kg) jika diperlukan
      double heightInCm = height;
      double weightInKg = weight;

      if (heightUnit == 'ft') {
        heightInCm = height * 30.48; // Convert feet to cm
      }
      
      if (weightUnit == 'lbs') {
        weightInKg = weight * 0.453592; // Convert lbs to kg
      }

      final headers = await _getHeaders();
      
      // Prepare body data sesuai dengan struktur database
      final body = json.encode({
        'height': heightInCm,
        'weight': weightInKg,
      });

      final response = await http.put(
        Uri.parse('$baseUrl/user/updateData'), // Perbaiki endpoint sesuai yang benar
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Update SharedPreferences dengan data baru
        await _updateLocalStorage({
          'height': heightInCm,
          'weight': weightInKg,
        });
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Body measurements updated successfully',
          'data': responseData['user'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['error'] ?? 'Failed to update body measurements',
          'errors': errorData['errors'],
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
    
    if (data.containsKey('height')) {
      await prefs.setDouble('height', data['height'].toDouble());
    }
    
    if (data.containsKey('weight')) {
      await prefs.setDouble('weight', data['weight'].toDouble());
    }
  }

  // Get current user data
  static Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user/currentUser'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Calculate BMI
  static double calculateBMI(double heightInCm, double weightInKg) {
    final heightInM = heightInCm / 100;
    return weightInKg / (heightInM * heightInM);
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal weight';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
}