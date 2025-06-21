import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class FoodDetectionService {
  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const String _detectEndpoint = '/detect';
  
  // Singleton pattern
  static final FoodDetectionService _instance = FoodDetectionService._internal();
  factory FoodDetectionService() => _instance;
  FoodDetectionService._internal();

  /// Mengirim gambar ke Express.js API untuk deteksi makanan
  Future<FoodDetectionResult> detectFood(String imagePath) async {
    try {
      // Validasi file gambar
      final file = File(imagePath);
      if (!await file.exists()) {
        throw FoodDetectionException('File gambar tidak ditemukan');
      }

      // Buat multipart request
      final uri = Uri.parse('$_baseUrl$_detectEndpoint');
      final request = http.MultipartRequest('POST', uri);
      
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
      } else {
        try {
          final errorData = json.decode(response.body);
          throw FoodDetectionException(
            errorData['error'] ?? 'Server error: ${response.statusCode}'
          );
        } catch (e) {
          throw FoodDetectionException('Server error: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw FoodDetectionException(
        'Tidak dapat terhubung ke server. Pastikan Express.js server berjalan di http://10.0.2.2:3000'
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
      final response = await http.get(
        Uri.parse(_baseUrl),
      ).timeout(Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      return false;
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