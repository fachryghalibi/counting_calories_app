import 'dart:convert';
import 'dart:io';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodDetectionService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static const String _detectEndpoint = '/scan';
  
  // Singleton pattern
  static final FoodDetectionService _instance = FoodDetectionService._internal();
  factory FoodDetectionService() => _instance;
  FoodDetectionService._internal();

  String? _cachedToken;

  /// Ambil token dari SharedPreferences
  Future<String?> _getAccessToken() async {
    // Jika sudah ada di cache, gunakan itu
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('access_token') ?? 
                    prefs.getString('token') ?? 
                    prefs.getString('auth_token');
      
      print('Token from SharedPreferences: ${_cachedToken != null ? "Found" : "Not found"}');
      return _cachedToken;
    } catch (e) {
      print('Error getting token from SharedPreferences: $e');
      return null;
    }
  }

  /// Hapus token dari cache dan SharedPreferences
  Future<void> clearToken() async {
    _cachedToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('token');
      await prefs.remove('auth_token');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  /// Mengirim gambar ke Express.js API untuk deteksi makanan
  Future<FoodDetectionResult> detectFood(String imagePath) async {
    try {
      // Dapatkan token dari SharedPreferences
      final accessToken = await _getAccessToken();
      
      // Validasi file gambar
      final file = File(imagePath);
      if (!await file.exists()) {
        throw FoodDetectionException('File gambar tidak ditemukan');
      }

      // Buat multipart request
      final uri = Uri.parse('$_baseUrl$_detectEndpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Tambahkan headers dengan token jika ada
      if (accessToken != null && accessToken.isNotEmpty) {
        // Cek apakah token sudah dalam format Bearer
        if (accessToken.toLowerCase().startsWith('bearer ')) {
          request.headers['Authorization'] = accessToken;
        } else {
          request.headers['Authorization'] = 'Bearer $accessToken';
        }
        print('Using token for authentication');
      } else {
        print('No token found - proceeding without authentication');
      }
      
      // Tambahkan headers umum
      request.headers['Accept'] = 'application/json';
      
      // Tambahkan file gambar
      request.files.add(
        await http.MultipartFile.fromPath('image', imagePath),
      );

      // Kirim request dengan timeout
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw FoodDetectionException('Request timeout - server tidak merespons');
        },
      );

      // Baca response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          
          // Cek apakah response sudah dalam format yang benar
          if (jsonData.containsKey('total_calorie') && jsonData.containsKey('items')) {
            return FoodDetectionResult.fromJson(jsonData);
          }
          // Jika response dalam format Express.js (dengan scan dan scanItems)
          else if (jsonData.containsKey('scan') && jsonData.containsKey('scanItems')) {
            return _parseExpressResponse(jsonData);
          }
          else {
            throw FoodDetectionException('Format response tidak dikenali');
          }
        } catch (e) {
          print('JSON decode error: $e');
          throw FoodDetectionException('Format response dari server tidak valid: $e');
        }
      } else if (response.statusCode == 401) {
        // Token invalid atau expired, hapus dari cache
        await clearToken();
        throw FoodDetectionException('Token tidak valid atau sudah expired. Silakan login kembali');
      } else {
        try {
          final errorData = json.decode(response.body);
          throw FoodDetectionException(
            errorData['message'] ?? errorData['error'] ?? 'Server error: ${response.statusCode}'
          );
        } catch (e) {
          throw FoodDetectionException('Server error: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw FoodDetectionException(
        'Tidak dapat terhubung ke server. Pastikan Express.js server berjalan di $_baseUrl'
      );
    } on FormatException catch (e) {
      throw FoodDetectionException('Format response dari server tidak valid: $e');
    } catch (e) {
      if (e is FoodDetectionException) {
        rethrow;
      }
      throw FoodDetectionException('Error tidak terduga: ${e.toString()}');
    }
  }

  /// Parse response dari Express.js format
  FoodDetectionResult _parseExpressResponse(Map<String, dynamic> jsonData) {
    final scan = jsonData['scan'];
    final scanItems = jsonData['scanItems'] as List<dynamic>?;
    
    return FoodDetectionResult(
      totalCalorie: scan['calories'] ?? 0,
      items: scanItems?.map((item) => DetectedFood(
        name: item['foodName'] ?? '',
        confidence: (item['confidence'] ?? 0.0).toDouble(),
        boundingBox: BoundingBox(
          x1: (item['x1'] ?? 0.0).toDouble(),
          y1: (item['y1'] ?? 0.0).toDouble(),
          x2: (item['x2'] ?? 0.0).toDouble(),
          y2: (item['y2'] ?? 0.0).toDouble(),
        ),
      )).toList() ?? [],
    );
  }

  /// Cek apakah server Express.js tersedia
  Future<bool> isServerAvailable() async {
    try {
      final accessToken = await _getAccessToken();
      final headers = <String, String>{};
      
      if (accessToken != null && accessToken.isNotEmpty) {
        if (accessToken.toLowerCase().startsWith('bearer ')) {
          headers['Authorization'] = accessToken;
        } else {
          headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      print('Server availability check error: $e');
      return false;
    }
  }

  /// Test connection dengan informasi token
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final accessToken = await _getAccessToken();
      final headers = <String, String>{};
      
      if (accessToken != null && accessToken.isNotEmpty) {
        if (accessToken.toLowerCase().startsWith('bearer ')) {
          headers['Authorization'] = accessToken;
        } else {
          headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: headers,
      ).timeout(Duration(seconds: 5));
      
      return {
        'success': true,
        'statusCode': response.statusCode,
        'body': response.body,
        'hasToken': accessToken != null && accessToken.isNotEmpty,
        'tokenPreview': accessToken != null ? '${accessToken.substring(0, 10)}...' : 'null',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'hasToken': false,
      };
    }
  }

  /// Cek apakah ada token tersimpan
  Future<bool> hasValidToken() async {
    final token = await _getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Debug: Print semua keys yang ada di SharedPreferences
  Future<void> debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      print('SharedPreferences keys: $keys');
      
      for (String key in keys) {
        if (key.toLowerCase().contains('token') || key.toLowerCase().contains('auth')) {
          final value = prefs.getString(key);
          print('$key: ${value != null ? "${value.substring(0, 10)}..." : "null"}');
        }
      }
    } catch (e) {
      print('Error debugging SharedPreferences: $e');
    }
  }
}

/// Model untuk hasil deteksi makanan
class FoodDetectionResult {
  final int totalCalorie;
  final List<DetectedFood> items;

  FoodDetectionResult({
    required this.totalCalorie,
    required this.items,
  });

  factory FoodDetectionResult.fromJson(Map<String, dynamic> json) {
    return FoodDetectionResult(
      totalCalorie: json['total_calorie'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => DetectedFood.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_calorie': totalCalorie,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

/// Model untuk makanan yang terdeteksi
class DetectedFood {
  final String name;
  final double confidence;
  final BoundingBox boundingBox;

  DetectedFood({
    required this.name,
    required this.confidence,
    required this.boundingBox,
  });

  factory DetectedFood.fromJson(Map<String, dynamic> json) {
    return DetectedFood(
      name: json['name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox(
        x1: (json['boxX1'] ?? 0.0).toDouble(),
        y1: (json['boxY1'] ?? 0.0).toDouble(),
        x2: (json['boxX2'] ?? 0.0).toDouble(),
        y2: (json['boxY2'] ?? 0.0).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'boxX1': boundingBox.x1,
      'boxY1': boundingBox.y1,
      'boxX2': boundingBox.x2,
      'boxY2': boundingBox.y2,
    };
  }

  /// Mendapatkan persentase confidence
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// Model untuk bounding box
class BoundingBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  BoundingBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  /// Mendapatkan lebar bounding box
  double get width => x2 - x1;

  /// Mendapatkan tinggi bounding box
  double get height => y2 - y1;

  /// Mendapatkan area bounding box
  double get area => width * height;
}

/// Exception khusus untuk Food Detection
class FoodDetectionException implements Exception {
  final String message;
  
  FoodDetectionException(this.message);
  
  @override
  String toString() => message;
}