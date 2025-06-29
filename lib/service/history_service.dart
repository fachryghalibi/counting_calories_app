import 'dart:convert';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Add this import

class HistoryService {
  static const String baseUrl = ApiConstants.baseUrl;
  
  // Helper method to get auth token
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? prefs.getString('token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }
  
  // Helper method to build headers with auth
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final token = await _getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Model untuk total kalori harian - FIXED TO HANDLE LIST RESPONSE
  static Future<Map<String, dynamic>> getDailyCalorieLog({
    String? startDate,
    String? endDate,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Prepare request body
      Map<String, dynamic> requestBody = {};
      
      // Add optional parameters to request body
      if (startDate != null) requestBody['startDate'] = startDate;
      if (endDate != null) requestBody['endDate'] = endDate;
      if (limit != null) requestBody['limit'] = limit;
      if (sortBy != null) requestBody['sortBy'] = sortBy;
      if (sortOrder != null) requestBody['sortOrder'] = sortOrder;
      
      // Try multiple possible endpoints
      final possibleEndpoints = [
        '$baseUrl/dayLog/calorieLog',
        '$baseUrl/api/dayLog/calorieLog',
        '$baseUrl/api/v1/dayLog/calorieLog',
        '$baseUrl/day-log/calorie-log',
        '$baseUrl/calorie-log',
      ];
      
      http.Response? response;
      String? workingEndpoint;
      
      for (String endpoint in possibleEndpoints) {
        try {
          print('Trying endpoint: $endpoint');
          print('Request body: ${json.encode(requestBody)}');
          
          response = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: json.encode(requestBody),
          );
          
          print('Response Status: ${response.statusCode}');
          print('Response Body: ${response.body}');
          
          if (response.statusCode != 404) {
            workingEndpoint = endpoint;
            break;
          }
        } catch (e) {
          print('Error with endpoint $endpoint: $e');
          continue;
        }
      }
      
      if (response == null) {
        throw ServiceException('No valid endpoint found');
      }
      
      print('Using endpoint: $workingEndpoint');
      print('Daily Calorie Log Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        
        // FIXED: Handle both List and Map responses
        if (jsonResponse is List) {
          // If API returns a list directly, wrap it in a map
          return {
            'data': jsonResponse,
            'message': 'Success'
          };
        } else if (jsonResponse is Map<String, dynamic>) {
          // If API returns a map, use it as is
          return jsonResponse;
        } else {
          throw DataException('Unexpected response format');
        }
      } else if (response.statusCode == 404) {
        return {
          'data': [],
          'message': 'No calorie log found'
        };
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Authentication required. Please login again.');
      } else if (response.statusCode == 400) {
        // Handle bad request
        String errorMessage = 'Bad request';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          // Use default error message if JSON parsing fails
        }
        throw HttpException(errorMessage);
      } else {
        // Try to parse error message from response
        String errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message if JSON parsing fails
        }
        throw HttpException(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: $e');
    } on FormatException catch (e) {
      throw DataException('Invalid response format: $e');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Unexpected error: $e');
    }
  }

  // Model untuk detail scan per hari
  static Future<Map<String, dynamic>> getDayDetailScans(String date) async {
    try {
      final headers = await _getHeaders();
      
      // Try multiple possible endpoints
      final possibleEndpoints = [
        '$baseUrl/dayLog/scans/$date',
        '$baseUrl/api/dayLog/scans/$date',
        '$baseUrl/api/v1/dayLog/scans/$date',
        '$baseUrl/day-log/scans/$date',
        '$baseUrl/scans/$date',
      ];
      
      http.Response? response;
      String? workingEndpoint;
      
      for (String endpoint in possibleEndpoints) {
        try {
          print('Trying endpoint: $endpoint');
          response = await http.get(
            Uri.parse(endpoint),
            headers: headers,
          );
          
          print('Response Status: ${response.statusCode}');
          
          if (response.statusCode != 404) {
            workingEndpoint = endpoint;
            break;
          }
        } catch (e) {
          print('Error with endpoint $endpoint: $e');
          continue;
        }
      }
      
      if (response == null) {
        throw ServiceException('No valid endpoint found');
      }
      
      print('Using endpoint: $workingEndpoint');
      print('Day Detail Scans Response Status: ${response.statusCode}');
      print('Day Detail Scans Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else if (response.statusCode == 404) {
        return {
          'id': 0,
          'date': date,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'userId': 0,
          'scans': [],
          'totalCalories': 0
        };
      } else if (response.statusCode == 401) {
        throw AuthenticationException('Authentication required. Please login again.');
      } else {
        // Try to parse error message from response
        String errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Use default error message if JSON parsing fails
        }
        throw HttpException(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: $e');
    } on FormatException catch (e) {
      throw DataException('Invalid response format: $e');
    } catch (e) {
      if (e is ServiceException) rethrow;
      throw ServiceException('Unexpected error: $e');
    }
  }
  
  // Debug method to test connectivity
  static Future<bool> testConnection() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/health'), // Try health check endpoint
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

// Custom Exception Classes
class ServiceException implements Exception {
  final String message;
  ServiceException(this.message);
  
  @override
  String toString() => message;
}

class NetworkException extends ServiceException {
  NetworkException(String message) : super(message);
}

class HttpException extends ServiceException {
  HttpException(String message) : super(message);
}

class DataException extends ServiceException {
  DataException(String message) : super(message);
}

class AuthenticationException extends ServiceException {
  AuthenticationException(String message) : super(message);
}

// Model classes with improved parsing...
class DailyCalorieLog {
  final List<DayCalorie> days;
  final String? message;

  DailyCalorieLog({required this.days, this.message});

  factory DailyCalorieLog.fromJson(Map<String, dynamic> json) {
    List<DayCalorie> daysList = [];
    
    // IMPROVED: Handle different response formats
    dynamic dataSource;
    
    if (json['data'] != null) {
      dataSource = json['data'];
    } else if (json['days'] != null) {
      dataSource = json['days'];
    } else {
      // If no nested structure, assume the whole json is the data
      dataSource = json;
    }
    
    if (dataSource is List) {
      for (var day in dataSource) {
        try {
          daysList.add(DayCalorie.fromJson(day));
        } catch (e) {
          print('Error parsing day data: $e');
        }
      }
    }
    
    return DailyCalorieLog(
      days: daysList,
      message: json['message']?.toString(),
    );
  }
}

class DayCalorie {
  final int id;
  final String date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final double? totalCalories;

  DayCalorie({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.totalCalories,
  });

  factory DayCalorie.fromJson(Map<String, dynamic> json) {
    return DayCalorie(
      id: json['id']?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      userId: json['userId']?.toInt() ?? 0,
      totalCalories: _parseDouble(json['totalCalories']),
    );
  }
  
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }
}

class DayDetailScans {
  final int id;
  final String date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final List<MealGroup> meals;
  final double totalCalories;

  DayDetailScans({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.meals,
    required this.totalCalories,
  });

  factory DayDetailScans.fromJson(Map<String, dynamic> json) {
    List<MealGroup> mealsList = [];
    
    // Handle the actual API response format
    if (json['scans'] != null && json['scans'] is List) {
      // Group scans by meal type based on time
      Map<String, List<Map<String, dynamic>>> groupedScans = {};
      
      for (var scan in json['scans']) {
        String timeEaten = scan['timeEaten']?.toString() ?? '';
        String mealType = _getMealTypeFromTime(timeEaten);
        
        if (!groupedScans.containsKey(mealType)) {
          groupedScans[mealType] = [];
        }
        groupedScans[mealType]!.add(scan);
      }
      
      // Convert grouped scans to MealGroup objects
      groupedScans.forEach((mealType, scans) {
        List<FoodItem> foods = [];
        String mealTime = '';
        
        for (var scan in scans) {
          // Get the main food item from the scan
          String foodName = scan['foodName']?.toString() ?? 'Unknown Food';
          double calories = DayCalorie._parseDouble(scan['calories']) ?? 0.0;
          String timeEaten = scan['timeEaten']?.toString() ?? '';
          
          if (mealTime.isEmpty) {
            mealTime = _formatTime(timeEaten);
          }
          
          // Add the main food item
          foods.add(FoodItem(
            name: foodName,
            calories: calories,
            portion: null,
            icon: _getFoodIcon(foodName),
          ));
          
          // Add individual items if available
          if (scan['items'] != null && scan['items'] is List) {
            for (var item in scan['items']) {
              String itemName = item['foodName']?.toString() ?? 'Unknown Item';
              double confidence = DayCalorie._parseDouble(item['confidence']) ?? 0.0;
              
              // Only add items with reasonable confidence and different names
              if (confidence > 0.5 && itemName != foodName) {
                foods.add(FoodItem(
                  name: itemName,
                  calories: calories * confidence, // Estimate calories based on confidence
                  portion: '${(confidence * 100).toInt()}% confidence',
                  icon: _getFoodIcon(itemName),
                ));
              }
            }
          }
        }
        
        double totalMealCalories = foods.fold(0.0, (sum, food) => sum + food.calories);
        
        mealsList.add(MealGroup(
          mealType: mealType,
          time: mealTime,
          foods: foods,
          totalCalories: totalMealCalories,
        ));
      });
    } else if (json['meals'] != null && json['meals'] is List) {
      // Handle the expected format (if API changes in future)
      for (var meal in json['meals']) {
        try {
          mealsList.add(MealGroup.fromJson(meal));
        } catch (e) {
          print('Error parsing meal data: $e');
        }
      }
    }
    
    // Calculate total calories from API or from meals
    double totalCal = DayCalorie._parseDouble(json['totalCalories']) ?? 0.0;
    if (totalCal == 0.0) {
      totalCal = mealsList.fold(0.0, (sum, meal) => sum + meal.totalCalories);
    }
    
    return DayDetailScans(
      id: json['id']?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      createdAt: DayCalorie._parseDateTime(json['createdAt']),
      updatedAt: DayCalorie._parseDateTime(json['updatedAt']),
      userId: json['userId']?.toInt() ?? 0,
      meals: mealsList,
      totalCalories: totalCal,
    );
  }
  
  // Helper method to determine meal type from time
  static String _getMealTypeFromTime(String timeStr) {
    if (timeStr.isEmpty) return 'Unknown';
    
    try {
      // Parse time string (format: "HH:mm:ss")
      List<String> timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        
        if (hour >= 5 && hour < 11) {
          return 'Breakfast';
        } else if (hour >= 11 && hour < 15) {
          return 'Lunch';
        } else if (hour >= 15 && hour < 18) {
          return 'Snack';
        } else if (hour >= 18 && hour < 22) {
          return 'Dinner';
        } else {
          return 'Late Night';
        }
      }
    } catch (e) {
      print('Error parsing time: $timeStr, error: $e');
    }
    
    return 'Unknown';
  }
  
  // Helper method to format time for display
  static String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    
    try {
      List<String> timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        
        String period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        
        return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      print('Error formatting time: $timeStr, error: $e');
    }
    
    return timeStr;
  }
  
  // Helper method to get appropriate food icon
  static String _getFoodIcon(String foodName) {
    String lowerName = foodName.toLowerCase();
    
    if (lowerName.contains('mie') || lowerName.contains('noodle')) {
      return '🍜';
    } else if (lowerName.contains('bakso')) {
      return '🍲';
    } else if (lowerName.contains('egg')) {
      return '🥚';
    } else if (lowerName.contains('peanut')) {
      return '🥜';
    } else if (lowerName.contains('cucumber')) {
      return '🥒';
    } else if (lowerName.contains('rendang')) {
      return '🍖';
    } else if (lowerName.contains('rice')) {
      return '🍚';
    } else if (lowerName.contains('juice')) {
      return '🥤';
    } else {
      return '🍽️';
    }
  }
}

class MealGroup {
  final String mealType;
  final String time;
  final List<FoodItem> foods;
  final double totalCalories;

  MealGroup({
    required this.mealType,
    required this.time,
    required this.foods,
    required this.totalCalories,
  });

  factory MealGroup.fromJson(Map<String, dynamic> json) {
    List<FoodItem> foodsList = [];
    
    if (json['foods'] != null && json['foods'] is List) {
      for (var food in json['foods']) {
        try {
          foodsList.add(FoodItem.fromJson(food));
        } catch (e) {
          print('Error parsing food data: $e');
        }
      }
    }
    
    double totalCal = 0;
    for (var food in foodsList) {
      totalCal += food.calories;
    }
    
    return MealGroup(
      mealType: json['mealType']?.toString() ?? 'Unknown',
      time: json['time']?.toString() ?? '',
      foods: foodsList,
      totalCalories: DayCalorie._parseDouble(json['totalCalories']) ?? totalCal,
    );
  }
}

class FoodItem {
  final String name;
  final double calories;
  final String? portion;
  final String? icon;

  FoodItem({
    required this.name,
    required this.calories,
    this.portion,
    this.icon,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name']?.toString() ?? 'Unknown Food',
      calories: DayCalorie._parseDouble(json['calories']) ?? 0.0,
      portion: json['portion']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}