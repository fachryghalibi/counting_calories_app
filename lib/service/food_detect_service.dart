import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodDetectionService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static const String _detectEndpoint = '/scan';
  
  // Progressive timeout strategy
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 180); // 3 minutes for AI processing
  static const int _maxRetries = 2; // Reduced retries for faster feedback
  static const Duration _retryDelay = Duration(seconds: 3);
  
  // Image compression settings
  static const int _maxImageSizeKB = 2048; // 2MB max
  static const int _compressionQuality = 85;
  
  // Singleton pattern
  static final FoodDetectionService _instance = FoodDetectionService._internal();
  factory FoodDetectionService() => _instance;
  FoodDetectionService._internal();

  String? _cachedToken;
  Timer? _progressTimer;

  /// Ambil token dari SharedPreferences
  Future<String?> _getAccessToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString('access_token') ?? 
                    prefs.getString('token') ?? 
                    prefs.getString('auth_token');
      
      print('Token from SharedPreferences: ${_cachedToken != null ? "Found (${_cachedToken!.length} chars)" : "Not found"}');
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

  /// Enhanced server health check with multiple endpoints
  Future<ServerStatus> checkServerHealth() async {
    try {
      final accessToken = await _getAccessToken();
      final headers = <String, String>{
        'Accept': 'application/json',
        'User-Agent': 'CalorieCountingApp/1.0',
      };
      
      if (accessToken != null && accessToken.isNotEmpty) {
        if (accessToken.toLowerCase().startsWith('bearer ')) {
          headers['Authorization'] = accessToken;
        } else {
          headers['Authorization'] = 'Bearer $accessToken';
        }
      }
      
      final stopwatch = Stopwatch()..start();
      
      // Try health endpoint first, fallback to base URL
      final healthEndpoints = ['$_baseUrl/health', '$_baseUrl/status', _baseUrl];
      
      for (String endpoint in healthEndpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: headers,
          ).timeout(_connectionTimeout);
          
          stopwatch.stop();
          
          if (response.statusCode >= 200 && response.statusCode < 500) {
            return ServerStatus(
              isAvailable: true,
              responseTime: stopwatch.elapsedMilliseconds,
              statusCode: response.statusCode,
              message: 'Server is available via $endpoint',
            );
          }
        } catch (e) {
          print('Health check failed for $endpoint: $e');
          continue;
        }
      }
      
      stopwatch.stop();
      return ServerStatus(
        isAvailable: false,
        responseTime: stopwatch.elapsedMilliseconds,
        statusCode: -1,
        message: 'All health check endpoints failed',
      );
      
    } catch (e) {
      return ServerStatus(
        isAvailable: false,
        responseTime: -1,
        statusCode: -1,
        message: _getErrorMessage(e),
      );
    }
  }

  /// Enhanced food detection with progressive timeout and better image handling
  Future<FoodDetectionResult> detectFood(String imagePath, {
    Function(String)? onStatusUpdate,
    Function(double)? onProgressUpdate,
  }) async {
    onStatusUpdate?.call('Initializing detection...');
    onProgressUpdate?.call(0.1);
    
    // Pre-flight checks
    onStatusUpdate?.call('Checking server connection...');
    final serverStatus = await checkServerHealth();
    if (!serverStatus.isAvailable) {
      throw FoodDetectionException(
        'Server tidak tersedia: ${serverStatus.message}\n'
        'Pastikan server berjalan di $_baseUrl'
      );
    }
    
    onProgressUpdate?.call(0.2);
    onStatusUpdate?.call('Server OK, preparing image...');
    
    // Validate and process image
    final processedImagePath = await _processImage(imagePath, onStatusUpdate);
    onProgressUpdate?.call(0.3);
    
    // Retry mechanism with progressive timeout
    FoodDetectionException? lastException;
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        onStatusUpdate?.call('Attempt $attempt/$_maxRetries - Uploading to AI...');
        onProgressUpdate?.call(0.3 + (0.6 * attempt / _maxRetries));
        
        final result = await _performDetection(
          processedImagePath, 
          onStatusUpdate,
          attempt,
        );
        
        onProgressUpdate?.call(1.0);
        onStatusUpdate?.call('Detection completed successfully!');
        
        // Cleanup processed image if different from original
        if (processedImagePath != imagePath) {
          try {
            await File(processedImagePath).delete();
          } catch (e) {
            print('Failed to cleanup processed image: $e');
          }
        }
        
        return result;
        
      } on SocketException catch (e) {
        lastException = FoodDetectionException(
          'Network error (attempt $attempt/$_maxRetries): Tidak dapat terhubung ke server.\n'
          'Periksa koneksi internet dan server.'
        );
        print('Connection failed on attempt $attempt: $e');
      } on TimeoutException catch (e) {
        lastException = FoodDetectionException(
          'Timeout (attempt $attempt/$_maxRetries): Server membutuhkan waktu lebih lama.\n'
          'AI mungkin sedang memproses request lain atau model sedang loading.'
        );
        print('Timeout on attempt $attempt: $e');
      } on FoodDetectionException catch (e) {
        // Don't retry for authentication or validation errors
        if (e.message.contains('401') || 
            e.message.contains('invalid') || 
            e.message.contains('expired') ||
            e.message.contains('413')) {
          rethrow;
        }
        lastException = e;
        print('Detection error on attempt $attempt: $e');
      } catch (e) {
        lastException = FoodDetectionException('Unexpected error: $e');
        print('Unexpected error on attempt $attempt: $e');
      }
      
      // Wait before retry (except for last attempt)
      if (attempt < _maxRetries) {
        onStatusUpdate?.call('Retrying in ${_retryDelay.inSeconds} seconds...');
        await Future.delayed(_retryDelay);
      }
    }
    
    // All attempts failed
    onProgressUpdate?.call(0.0);
    throw lastException ?? FoodDetectionException('All detection attempts failed');
  }

  /// Process and optimize image before sending
  Future<String> _processImage(String imagePath, Function(String)? onStatusUpdate) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw FoodDetectionException('File gambar tidak ditemukan: $imagePath');
    }
    
    final fileSizeKB = await file.length() / 1024;
    print('Original image size: ${fileSizeKB.toStringAsFixed(1)} KB');
    
    // If image is already small enough, use original
    if (fileSizeKB <= _maxImageSizeKB) {
      onStatusUpdate?.call('Image size OK, using original');
      return imagePath;
    }
    
    // Image is too large, need to compress (placeholder for actual compression)
    onStatusUpdate?.call('Image too large (${fileSizeKB.toStringAsFixed(0)}KB), optimizing...');
    
    // For now, return original path
    // In production, implement actual image compression here
    print('WARNING: Image size ${fileSizeKB.toStringAsFixed(1)}KB exceeds recommended ${_maxImageSizeKB}KB');
    return imagePath;
  }

  /// Perform the actual detection request with enhanced timeout handling
  Future<FoodDetectionResult> _performDetection(
    String imagePath, 
    Function(String)? onStatusUpdate,
    int attemptNumber,
  ) async {
    final accessToken = await _getAccessToken();
    
    // Create multipart request
    final uri = Uri.parse('$_baseUrl$_detectEndpoint');
    final request = http.MultipartRequest('POST', uri);
    
    // Add headers with more details
    request.headers['Accept'] = 'application/json';
    request.headers['User-Agent'] = 'CalorieCountingApp/1.0';
    request.headers['X-Request-Timeout'] = '${_receiveTimeout.inSeconds}';
    request.headers['X-Attempt-Number'] = attemptNumber.toString();
    
    if (accessToken != null && accessToken.isNotEmpty) {
      if (accessToken.toLowerCase().startsWith('bearer ')) {
        request.headers['Authorization'] = accessToken;
      } else {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    
    // Add image file with metadata
    final imageFile = await http.MultipartFile.fromPath('image', imagePath);
    request.files.add(imageFile);
    
    // Add additional metadata
    request.fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    request.fields['client'] = 'flutter_app';

    print('Sending request to: $uri (attempt $attemptNumber)');
    print('Image file size: ${imageFile.length} bytes');
    onStatusUpdate?.call('Uploading image to AI server...');
    
    // Start progress timer
    _startProgressTimer(onStatusUpdate);
    
    try {
      // Send request with progressive timeout based on attempt
      final timeoutDuration = Duration(
        seconds: _receiveTimeout.inSeconds + (attemptNumber * 30)
      );
      
      final streamedResponse = await request.send().timeout(
        timeoutDuration,
        onTimeout: () {
          _stopProgressTimer();
          throw TimeoutException(
            'AI processing timeout after ${timeoutDuration.inSeconds} seconds.\n'
            'Server might be processing other requests or model is loading.\n'
            'Try again in a few moments.',
            timeoutDuration,
          );
        },
      );

      _stopProgressTimer();

      // Read response
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...');
      
      return _handleResponse(response);
      
    } catch (e) {
      _stopProgressTimer();
      rethrow;
    }
  }

  /// Start progress timer for long-running operations
  void _startProgressTimer(Function(String)? onStatusUpdate) {
    int seconds = 0;
    _progressTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      seconds += 10;
      if (seconds <= 60) {
        onStatusUpdate?.call('AI is processing... (${seconds}s)');
      } else if (seconds <= 120) {
        onStatusUpdate?.call('Still processing, please wait... (${seconds}s)');
      } else {
        onStatusUpdate?.call('Taking longer than usual... (${seconds}s)');
      }
    });
  }

  /// Stop progress timer
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// Enhanced response handler with better error messages
 /// Enhanced response handler with better error messages
FoodDetectionResult _handleResponse(http.Response response) {
  // Handle success responses (2xx range)
  if (response.statusCode >= 200 && response.statusCode < 300) {
    try {
      final jsonData = json.decode(response.body);
      
      // Handle different response formats
      if (jsonData.containsKey('total_calorie') && jsonData.containsKey('items')) {
        return FoodDetectionResult.fromJson(jsonData);
      }
      else if (jsonData.containsKey('scan') && jsonData.containsKey('scanItems')) {
        return _parseExpressResponse(jsonData);
      }
      else if (jsonData.containsKey('calories') && jsonData.containsKey('foods')) {
        return _parsePythonResponse(jsonData);
      }
      else {
        print('Unknown response format: ${jsonData.keys}');
        throw FoodDetectionException('Format response tidak dikenali. Server mungkin menggunakan format API yang berbeda.');
      }
    } catch (e) {
      print('JSON decode error: $e');
      print('Raw response: ${response.body}');
      throw FoodDetectionException('Format response dari server tidak valid: $e');
    }
  } 
  else if (response.statusCode == 400) {
    try {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Bad request';
      
      if (errorMessage.toString().toLowerCase().contains('timeout')) {
        throw FoodDetectionException(
          'Server timeout: AI membutuhkan waktu lebih lama untuk memproses gambar.\n'
          'Coba lagi dalam beberapa saat atau gunakan gambar yang lebih kecil.'
        );
      } else {
        throw FoodDetectionException('Request error: $errorMessage');
      }
    } catch (e) {
      throw FoodDetectionException('Server timeout atau gambar tidak dapat diproses. Coba lagi.');
    }
  }
  else if (response.statusCode == 401) {
    clearToken(); // Clear invalid token
    throw FoodDetectionException('Token tidak valid atau sudah expired. Silakan login kembali.');
  }
  else if (response.statusCode == 413) {
    throw FoodDetectionException('File gambar terlalu besar (max ${_maxImageSizeKB}KB). Coba kompres gambar terlebih dahulu.');
  }
  else if (response.statusCode == 429) {
    throw FoodDetectionException('Terlalu banyak request. Tunggu 30 detik sebelum mencoba lagi.');
  }
  else if (response.statusCode == 503) {
    throw FoodDetectionException('Server sedang overload atau maintenance. Coba lagi dalam beberapa menit.');
  }
  else if (response.statusCode >= 500) {
    throw FoodDetectionException('Server error (${response.statusCode}). Server mungkin sedang restart atau mengalami masalah.');
  }
  else {
    try {
      final errorData = json.decode(response.body);
      throw FoodDetectionException(
        errorData['message'] ?? errorData['error'] ?? 'Server error: ${response.statusCode}'
      );
    } catch (e) {
      throw FoodDetectionException('Server error: ${response.statusCode}');
    }
  }
}

  /// Parse response dari Express.js format
  FoodDetectionResult _parseExpressResponse(Map<String, dynamic> jsonData) {
    final scan = jsonData['scan'];
    final scanItems = jsonData['scanItems'] as List<dynamic>?;
    
    return FoodDetectionResult(
      totalCalorie: (scan['calories'] ?? 0).round(),
      items: scanItems?.map((item) => DetectedFood(
        name: item['foodName']?.toString() ?? '',
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

  /// Parse response dari Python/Flask format
  FoodDetectionResult _parsePythonResponse(Map<String, dynamic> jsonData) {
    final foods = jsonData['foods'] as List<dynamic>? ?? [];
    
    return FoodDetectionResult(
      totalCalorie: (jsonData['calories'] ?? 0).round(),
      items: foods.map((item) => DetectedFood(
        name: item['name']?.toString() ?? '',
        confidence: (item['confidence'] ?? 0.0).toDouble(),
        boundingBox: BoundingBox(
          x1: (item['bbox']?[0] ?? 0.0).toDouble(),
          y1: (item['bbox']?[1] ?? 0.0).toDouble(),
          x2: (item['bbox']?[2] ?? 0.0).toDouble(),
          y2: (item['bbox']?[3] ?? 0.0).toDouble(),
        ),
      )).toList(),
    );
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet dan pastikan server berjalan di $_baseUrl';
    } else if (error is TimeoutException) {
      return 'Koneksi timeout. Server mungkin sedang sibuk atau membutuhkan waktu lebih lama untuk memproses AI';
    } else if (error is FormatException) {
      return 'Format response dari server tidak valid';
    } else if (error is HttpException) {
      return 'HTTP error: ${error.message}';
    } else {
      return error.toString();
    }
  }

  // Legacy methods for backward compatibility
  Future<bool> isServerAvailable() async {
    final status = await checkServerHealth();
    return status.isAvailable;
  }

  /// Enhanced connection test with comprehensive diagnostics
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      final status = await checkServerHealth();
      stopwatch.stop();
      
      final accessToken = await _getAccessToken();
      
      return {
        'success': status.isAvailable,
        'statusCode': status.statusCode,
        'responseTime': status.responseTime,
        'totalTime': stopwatch.elapsedMilliseconds,
        'message': status.message,
        'hasToken': accessToken != null && accessToken.isNotEmpty,
        'tokenLength': accessToken?.length ?? 0,
        'serverUrl': _baseUrl,
        'endpoints': {
          'scan': '$_baseUrl$_detectEndpoint',
          'health': '$_baseUrl/health',
        },
        'timeouts': {
          'connection': _connectionTimeout.inSeconds,
          'receive': _receiveTimeout.inSeconds,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'hasToken': false,
        'serverUrl': _baseUrl,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check if there's a valid token
  Future<bool> hasValidToken() async {
    final token = await _getAccessToken();
    return token != null && token.isNotEmpty && token.length > 10;
  }

  /// Debug SharedPreferences with more detailed info
  Future<Map<String, dynamic>> debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final tokenKeys = keys.where((key) => 
        key.toLowerCase().contains('token') || 
        key.toLowerCase().contains('auth')
      ).toList();
      
      final tokenInfo = <String, dynamic>{};
      for (String key in tokenKeys) {
        final value = prefs.getString(key);
        tokenInfo[key] = {
          'exists': value != null,
          'length': value?.length ?? 0,
          'preview': value != null && value.length > 10 ? "${value.substring(0, 10)}..." : value,
        };
      }
      
      return {
        'totalKeys': keys.length,
        'tokenKeys': tokenKeys,
        'tokens': tokenInfo,
        'hasAccessToken': tokenInfo.containsKey('access_token'),
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Cleanup resources
  void dispose() {
    _stopProgressTimer();
    _cachedToken = null;
  }
}

/// Server status information with enhanced details
class ServerStatus {
  final bool isAvailable;
  final int responseTime; // in milliseconds
  final int statusCode;
  final String message;

  ServerStatus({
    required this.isAvailable,
    required this.responseTime,
    required this.statusCode,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'isAvailable': isAvailable,
      'responseTime': responseTime,
      'statusCode': statusCode,
      'message': message,
    };
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
      totalCalorie: (json['total_calorie'] ?? json['calories'] ?? 0).round(),
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

  bool get hasResults => items.isNotEmpty;
  int get foodCount => items.length;
  double get averageConfidence => items.isEmpty ? 0.0 : 
    items.map((e) => e.confidence).reduce((a, b) => a + b) / items.length;
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
      name: json['name']?.toString() ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: BoundingBox(
        x1: (json['boxX1'] ?? json['x1'] ?? 0.0).toDouble(),
        y1: (json['boxY1'] ?? json['y1'] ?? 0.0).toDouble(),
        x2: (json['boxX2'] ?? json['x2'] ?? 0.0).toDouble(),
        y2: (json['boxY2'] ?? json['y2'] ?? 0.0).toDouble(),
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

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.5;
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

  double get width => (x2 - x1).abs();
  double get height => (y2 - y1).abs();
  double get area => width * height;
  double get centerX => (x1 + x2) / 2;
  double get centerY => (y1 + y2) / 2;
}

/// Exception khusus untuk Food Detection dengan kategori error
class FoodDetectionException implements Exception {
  final String message;
  final String? category;
  final int? statusCode;
  
  FoodDetectionException(this.message, {this.category, this.statusCode});
  
  @override
  String toString() => message;

  bool get isNetworkError => category == 'network' || message.contains('connection') || message.contains('timeout');
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isAuthError => statusCode == 401 || message.contains('token') || message.contains('auth');
}