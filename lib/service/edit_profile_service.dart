import 'dart:convert';
import 'dart:io';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);
  static const int _maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  
  // List of common field names to try for image upload
  static const List<String> _commonImageFieldNames = [
    'image',
    'file', 
    'avatar',
    'photo',
    'picture',
    'profileImage',
    'profile_image',
    'profilePicture',
    'profile_picture'
  ];
  
  // Helper method to construct full image URL using the general endpoint
  static String constructImageUrl(String? imageId) {
    if (imageId == null || imageId.isEmpty) return '';
    
    // If it's already a full URL, return as is
    if (imageId.startsWith('http://') || imageId.startsWith('https://')) {
      return imageId;
    }
    
    // Use the general storage endpoint
    return '$baseUrl/storage/file/$imageId';
  }
  
  // Update user data (email, username, etc.)
  static Future<ApiResponse> updateUserData({
    String? username,
    String? email,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    int? activityLevel,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return ApiResponse.error('Authentication token not found. Please login again.');
      }

      // Validate inputs before sending
      final validationResult = _validateUserData(
        username: username,
        email: email,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
      );
      
      if (!validationResult.success) {
        return validationResult;
      }

      // Build request body with only non-null, non-empty values
      final requestBody = _buildUpdateRequestBody(
        username: username,
        email: email,
        dateOfBirth: dateOfBirth,
        gender: gender,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
      );

      if (requestBody.isEmpty) {
        return ApiResponse.error('No data provided for update');
      }

      print('🔄 Updating user data with: $requestBody');

      final response = await http.put(
        Uri.parse('$baseUrl/user/updateData'),
        headers: _getJsonHeaders(token),
        body: json.encode(requestBody),
      ).timeout(_defaultTimeout);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      return await _handleUpdateResponse(response, requestBody);

    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException {
      return ApiResponse.error('Server communication error. Please try again.');
    } on FormatException {
      return ApiResponse.error('Invalid data format. Please try again.');
    } catch (e) {
      print('❌ Error updating user data: $e');
      return ApiResponse.error('An unexpected error occurred. Please try again.');
    }
  }

  // Update profile image with multiple field name attempts
  static Future<ApiResponse> updateProfileImage(File imageFile) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return ApiResponse.error('Authentication token not found. Please login again.');
      }

      // Validate image file
      final validationResult = await _validateImageFile(imageFile);
      if (!validationResult.success) {
        return validationResult;
      }

      print('🔄 Uploading profile image: ${imageFile.path}');

      // Try different field names until one works
      for (String fieldName in _commonImageFieldNames) {
        print('🔄 Trying field name: $fieldName');
        
        final result = await _attemptImageUpload(imageFile, token, fieldName);
        
        if (result.success) {
          print('✅ Upload successful with field name: $fieldName');
          return result;
        }
        
        // If it's not a field name error, return the error immediately
        if (result.message != null && 
            !result.message!.toLowerCase().contains('unexpected field') &&
            !result.message!.toLowerCase().contains('field') &&
            result.message != 'Server communication error. Please try again.') {
          return result;
        }
        
        print('❌ Failed with field name: $fieldName, trying next...');
      }

      return ApiResponse.error('Failed to upload image. Server expects different field name.');

    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException {
      return ApiResponse.error('Server communication error. Please try again.');
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      return ApiResponse.error('Failed to upload image. Please try again.');
    }
  }

  // Helper method to attempt image upload with specific field name
  static Future<ApiResponse> _attemptImageUpload(File imageFile, String token, String fieldName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/updateProfilePicture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      // Add the image file with the specified field name
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          imageFile.path,
          // Add content type explicitly
          // contentType: MediaType('image', getFileExtension(imageFile.path)),
        ),
      );

      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Profile image upload response status: ${response.statusCode}');
      print('📡 Profile image upload response body: ${response.body}');

      return await _handleImageUploadResponse(response);

    } catch (e) {
      print('❌ Error in _attemptImageUpload with field $fieldName: $e');
      return ApiResponse.error('Server communication error. Please try again.');
    }
  }

  // Update password
  // Update password - FIXED: Changed from PUT to POST
static Future<ApiResponse> updatePassword({
  required String oldPassword,
  required String newPassword,
}) async {
  try {
    final token = await _getAuthToken();
    if (token == null) {
      return ApiResponse.error('Authentication token not found. Please login again.');
    }

    // Validate passwords
    if (oldPassword.trim().isEmpty) {
      return ApiResponse.error('Current password is required');
    }

    if (!isValidPassword(newPassword)) {
      return ApiResponse.error('New password must be at least 6 characters long');
    }

    if (oldPassword.trim() == newPassword.trim()) {
      return ApiResponse.error('New password must be different from current password');
    }

    final requestBody = {
      'oldPassword': oldPassword.trim(),
      'newPassword': newPassword.trim(),
    };

    print('🔄 Updating password...');

    // FIXED: Changed from http.put to http.post
    final response = await http.post(
      Uri.parse('$baseUrl/user/updatePassword'),
      headers: _getJsonHeaders(token),
      body: json.encode(requestBody),
    ).timeout(_defaultTimeout);

    print('📡 Password update response status: ${response.statusCode}');

    final responseData = _parseJsonResponse(response.body);
    if (responseData == null) {
      return ApiResponse.error('Invalid server response');
    }

    if (response.statusCode == 200) {
      return ApiResponse.success(
        message: responseData['message'] ?? 'Password updated successfully',
      );
    } else {
      return ApiResponse.error(
        responseData['error'] ?? 
        responseData['message'] ?? 
        'Failed to update password'
      );
    }

  } on SocketException {
    return ApiResponse.error('No internet connection. Please check your network.');
  } on HttpException {
    return ApiResponse.error('Server communication error. Please try again.');
  } catch (e) {
    print('❌ Error updating password: $e');
    return ApiResponse.error('Network error. Please try again.');
  }
}

  // Get current user data
  // Fix for the unnecessary type check in getCurrentUser() method
// Original problematic line:
// final userData = responseData is Map<String, dynamic> ? responseData : {};

// Fixed version:
static Future<ApiResponse> getCurrentUser() async {
  try {
    final token = await _getAuthToken();
    if (token == null) {
      return ApiResponse.error('Authentication token not found. Please login again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/currentUser'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ).timeout(_defaultTimeout);

    print('📡 Get current user response status: ${response.statusCode}');
    print('📡 Get current user response body: ${response.body}');

    final responseData = _parseJsonResponse(response.body);
    if (responseData == null) {
      return ApiResponse.error('Invalid server response');
    }

    if (response.statusCode == 200) {
      // Process profile image ID to full URL
      // FIXED: Remove unnecessary type check since responseData is already Map<String, dynamic>?
      final userData = responseData; // Simply use responseData directly
      
      // Alternative approach if you want to ensure it's not null:
      // final userData = responseData ?? <String, dynamic>{};
      
      // Check for profile image ID and convert to full URL
      final profileImageId = userData['profileImage'] ?? 
                            userData['profile_image'] ?? 
                            userData['profileImageId'] ?? 
                            userData['imageId'];
      
      if (profileImageId != null && profileImageId.toString().isNotEmpty) {
        final fullImageUrl = constructImageUrl(profileImageId.toString());
        userData['profileImageUrl'] = fullImageUrl;
        userData['profileImage'] = fullImageUrl; // Keep both for compatibility
        
        print('✅ Profile image URL constructed: $fullImageUrl');
      }
      
      return ApiResponse.success(data: userData);
    } else {
      return ApiResponse.error(
        responseData['message'] ?? 
        responseData['error'] ?? 
        'Failed to get user data'
      );
    }

  } on SocketException {
    return ApiResponse.error('No internet connection. Please check your network.');
  } on HttpException {
    return ApiResponse.error('Server communication error. Please try again.');
  } catch (e) {
    print('❌ Error getting current user: $e');
    return ApiResponse.error('Network error. Please try again.');
  }
}

  // Delete profile image
  static Future<ApiResponse> deleteProfileImage() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return ApiResponse.error('Authentication token not found. Please login again.');
      }

      print('🔄 Deleting profile image...');

      final response = await http.delete(
        Uri.parse('$baseUrl/user/deleteProfileImage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(_defaultTimeout);

      print('📡 Delete profile image response status: ${response.statusCode}');
      print('📡 Delete profile image response body: ${response.body}');

      final responseData = _parseJsonResponse(response.body);
      if (responseData == null) {
        return ApiResponse.error('Invalid server response');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove profile image from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('profileImage');
        await prefs.remove('profile_image');
        await prefs.remove('profileImageUrl');

        return ApiResponse.success(
          message: responseData['message'] ?? 'Profile image deleted successfully',
        );
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 
          responseData['error'] ?? 
          'Failed to delete profile image'
        );
      }

    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException {
      return ApiResponse.error('Server communication error. Please try again.');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
      return ApiResponse.error('Network error. Please try again.');
    }
  }

  // Private helper methods
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token') ?? prefs.getString('token');
    } catch (e) {
      print('❌ Error getting auth token: $e');
      return null;
    }
  }

  static Map<String, String> _getJsonHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static Map<String, dynamic>? _parseJsonResponse(String responseBody) {
    try {
      if (responseBody.isEmpty) {
        return {'message': 'Empty response'};
      }
      return json.decode(responseBody);
    } catch (e) {
      print('❌ Error parsing JSON response: $e');
      print('📡 Raw response body: $responseBody');
      return null;
    }
  }

  static ApiResponse _validateUserData({
    String? username,
    String? email,
    double? height,
    double? weight,
    int? activityLevel,
  }) {
    if (username != null && !isValidUsername(username)) {
      return ApiResponse.error('Username must be between 3 and 50 characters');
    }

    if (email != null && !isValidEmail(email)) {
      return ApiResponse.error('Please enter a valid email address');
    }

    if (height != null && !isValidHeight(height)) {
      return ApiResponse.error('Height must be between 1 and 500 cm');
    }

    if (weight != null && !isValidWeight(weight)) {
      return ApiResponse.error('Weight must be between 1 and 500 kg');
    }

    if (activityLevel != null && !isValidActivityLevel(activityLevel)) {
      return ApiResponse.error('Activity level must be between 1 and 4');
    }

    return ApiResponse.success();
  }

  static Future<ApiResponse> _validateImageFile(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        return ApiResponse.error('Selected image file does not exist.');
      }

      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSizeBytes) {
        return ApiResponse.error('Image size should be less than ${formatFileSize(_maxImageSizeBytes)}.');
      }

      if (fileSize == 0) {
        return ApiResponse.error('Selected image file is empty.');
      }

      if (!isValidImageFile(imageFile.path)) {
        return ApiResponse.error('Only JPG, JPEG, and PNG files are allowed.');
      }

      return ApiResponse.success();
    } catch (e) {
      print('❌ Error validating image file: $e');
      return ApiResponse.error('Error validating image file.');
    }
  }

  static Map<String, dynamic> _buildUpdateRequestBody({
    String? username,
    String? email,
    String? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    int? activityLevel,
  }) {
    final requestBody = <String, dynamic>{};

    void addIfValid(String key, dynamic value) {
      if (value != null) {
        if (value is String && value.trim().isNotEmpty) {
          requestBody[key] = value.trim();
        } else if (value is! String) {
          requestBody[key] = value;
        }
      }
    }

    addIfValid('username', username);
    addIfValid('email', email);
    addIfValid('dateOfBirth', dateOfBirth);
    addIfValid('gender', gender);
    addIfValid('height', height);
    addIfValid('weight', weight);
    addIfValid('activityLevel', activityLevel);

    return requestBody;
  }

  static Future<ApiResponse> _handleUpdateResponse(
    http.Response response,
    Map<String, dynamic> requestBody,
  ) async {
    final responseData = _parseJsonResponse(response.body);
    if (responseData == null) {
      return ApiResponse.error('Invalid server response');
    }

    if (response.statusCode == 200) {
      // Update local storage with new data
      await _updateLocalStorage(requestBody);

      return ApiResponse.success(
        message: responseData['message'] ?? 'Profile updated successfully',
        data: responseData['user'] ?? responseData['data'],
      );
    } else {
      return ApiResponse.error(
        responseData['message'] ?? 
        responseData['error'] ?? 
        'Failed to update profile',
        errors: responseData['errors'],
      );
    }
  }

  static Future<ApiResponse> _handleImageUploadResponse(http.Response response) async {
    final responseData = _parseJsonResponse(response.body);
    if (responseData == null) {
      return ApiResponse.error('Invalid server response');
    }

    print('🔍 Debug - Full response data: $responseData');

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Extract image ID from various possible fields
      final imageId = responseData['imageId'] ?? 
                     responseData['profileImageId'] ?? 
                     responseData['data']?['imageId'] ?? 
                     responseData['data']?['profileImageId'] ??
                     responseData['data']?['profileImage'] ??
                     responseData['data']?['profile_image'] ??
                     responseData['profileImage'] ??
                     responseData['profile_image'] ??
                     responseData['id'] ??
                     responseData['fileId'] ??
                     responseData['file_id'];
      
      print('🔍 Debug - Extracted image ID: $imageId');
      
      String fullImageUrl = '';
      
      if (imageId != null && imageId.toString().isNotEmpty) {
        // Construct full URL using the general storage endpoint
        fullImageUrl = constructImageUrl(imageId.toString());
        print('✅ Profile image URL constructed: $fullImageUrl');
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profileImage', fullImageUrl);
          await prefs.setString('profile_image', fullImageUrl);  
          await prefs.setString('profileImageUrl', fullImageUrl);
          await prefs.setString('profileImageId', imageId.toString());
          print('✅ Profile image data saved to SharedPreferences');
        } catch (e) {
          print('❌ Error saving profile image data to SharedPreferences: $e');
        }
      } else {
        print('⚠️ Warning - No image ID found in response');
        
        // Fallback: try to find direct URL in response
        final directUrl = responseData['profileImageUrl'] ?? 
                         responseData['data']?['profileImageUrl'] ??
                         responseData['url'] ?? 
                         responseData['imageUrl'] ?? '';
        
        if (directUrl.isNotEmpty) {
          fullImageUrl = directUrl;
          print('✅ Using direct URL from response: $fullImageUrl');
          
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profileImage', fullImageUrl);
            await prefs.setString('profile_image', fullImageUrl);
            await prefs.setString('profileImageUrl', fullImageUrl);
            print('✅ Direct profile image URL saved to SharedPreferences');
          } catch (e) {
            print('❌ Error saving direct profile image URL to SharedPreferences: $e');
          }
        }
      }

      return ApiResponse.success(
        message: responseData['message'] ?? 'Profile image updated successfully',
        data: {
          'profileImageUrl': fullImageUrl,
          'profileImageId': imageId?.toString(),
          'fullResponse': responseData, // Include full response for debugging
        },
      );
    } else {
      return ApiResponse.error(
        responseData['message'] ?? 
        responseData['error'] ?? 
        'Failed to upload profile image'
      );
    }
  }

  static Future<void> _updateLocalStorage(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in data.entries) {
        switch (entry.key) {
          case 'username':
          case 'email':
          case 'dateOfBirth':
          case 'gender':
            if (entry.value is String) {
              await prefs.setString(entry.key, entry.value);
              // Also save with alternative keys
              if (entry.key == 'username') {
                await prefs.setString('full_name', entry.value);
              }
            }
            break;
          case 'height':
          case 'weight':
            if (entry.value is double) {
              await prefs.setDouble(entry.key, entry.value);
            } else if (entry.value is int) {
              await prefs.setDouble(entry.key, entry.value.toDouble());
            }
            break;
          case 'activityLevel':
            if (entry.value is int) {
              await prefs.setInt(entry.key, entry.value);
            }
            break;
        }
      }
    } catch (e) {
      print('❌ Error updating local storage: $e');
    }
  }

  // Validation methods
  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidUsername(String username) {
    final trimmed = username.trim();
    return trimmed.length >= 3 && trimmed.length <= 50;
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

  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  static bool isValidImageFile(String filePath) {
    final extension = getFileExtension(filePath);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// Response wrapper class for better type safety
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final dynamic errors;

  ApiResponse._({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.success({String? message, dynamic data}) {
    return ApiResponse._(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {dynamic errors}) {
    return ApiResponse._(
      success: false,
      message: message,
      errors: errors,
    );
  }

  // Convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
      if (errors != null) 'errors': errors,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, errors: $errors)';
  }
}