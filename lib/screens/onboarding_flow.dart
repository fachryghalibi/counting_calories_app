import 'package:aplikasi_counting_calories/screens/pages/body_measure_page.dart';
import 'package:aplikasi_counting_calories/service/base_url_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_data.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/progress_bar.dart';
import 'pages/activity_level_page.dart';
import 'pages/personal_info_page.dart';
import 'package:aplikasi_counting_calories/service/activity_level_service.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  PageController _pageController = PageController();
  int currentPage = 0;
  UserData userData = UserData();
  bool _isLoading = false;

  final List<String> pageTitles = [
    'Personal Info',
    'Your Body', 
    'Activity Level',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: pageTitles[currentPage],
              showBackButton: currentPage > 0,
              onBackPressed: _previousPage,
            ),
            ProgressBar(
              currentStep: currentPage + 1,
              totalSteps: 3,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                children: [
                  PersonalInfoPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                    onNext: _nextPage,
                    showNextButton: true,
                  ),
                  BodyMeasurementsPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                    onNext: _nextPage,
                    showNextButton: true,
                  ),
                  ActivityLevelPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                    onNext: _saveActivityLevelAndComplete,
                    showNextButton: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (currentPage < 2) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  Future<void> _saveActivityLevelAndComplete() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting save activity level and complete onboarding...');
      
      if (userData.activityLevel == null) {
        throw Exception('Please select an activity level');
      }

      int activityLevelValue = userData.activityLevel!;
      
      if (activityLevelValue < 1 || activityLevelValue > 5) {
        throw Exception('Invalid activity level selected');
      }

      print('📊 Activity level integer: $activityLevelValue');

      final result = await ActivityLevelService.updateActivityLevel(
        activityLevel: activityLevelValue,
      );

      print('🔄 Activity level service result: $result');

      if (result['success']) {
        print('✅ Activity level saved to database successfully');
        await _completeOnboarding();
      } else {
        throw Exception(result['message'] ?? 'Failed to save activity level');
      }

    } catch (e) {
      print('❌ Error saving activity level: $e');
      _showErrorDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ FIXED: Updated to properly handle double values
  Future<bool> _updateOnboardingStatusInDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('id') ?? 0;
      
      // Debug: Print all stored keys
      print('🔍 Debug: All SharedPreferences keys:');
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.toLowerCase().contains('token') || key.toLowerCase().contains('auth')) {
          print('   - $key: ${prefs.getString(key)}');
        }
      }
      
      // Try different token key possibilities
      String? token = prefs.getString('token') ?? 
                     prefs.getString('auth_token') ?? 
                     prefs.getString('access_token') ??
                     prefs.getString('jwt_token') ??
                     prefs.getString('api_token');

      print('🔄 User ID: $userId');
      print('🔄 Token found: ${token != null ? "Yes (${token.length} chars)" : "No"}');

      if (userId == 0) {
        print('❌ Error: Missing user ID');
        return false;
      }

      const String baseUrl = ApiConstants.baseUrl;
      final String url = '$baseUrl/user/setupAccount';

      print('🔄 Calling setupAccount endpoint: $url');

      // Create headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      // Add Authorization header if token available
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        print('🔄 Using token authentication');
      } else {
        print('🔄 No token found, proceeding without authentication header');
      }

      // ✅ FIXED: Direct double values from userData
      final requestBody = {
        'userId': userId,
        'username': userData.firstName.isNotEmpty ? userData.firstName : 'User',
        'gender': userData.gender,
        'height': userData.height,        // Already double
        'weight': userData.weight,        // Already double
        'activityLevel': userData.activityLevel,
        'completedOnboarding': 1,
      };

      // Handle dateOfBirth
      if (userData.birthDate != null) {
        requestBody['dateOfBirth'] = userData.birthDate!.toIso8601String().split('T')[0];
      } else if (userData.birthYear != null && userData.birthMonth != null && userData.birthDay != null) {
        final dateStr = '${userData.birthYear!.toString().padLeft(4, '0')}-${userData.birthMonth!.toString().padLeft(2, '0')}-${userData.birthDay!.toString().padLeft(2, '0')}';
        requestBody['dateOfBirth'] = dateStr;
      }

      print('🔄 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('🔄 Response status: ${response.statusCode}');
      print('🔄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Onboarding status updated successfully in database');
        return true;
      } else if (response.statusCode == 500 && response.body.contains('Setup for this account is already completed')) {
        print('✅ Onboarding already completed for this account');
        return true;
      } else {
        print('❌ Failed to update onboarding status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return false;
      }

    } catch (e) {
      print('❌ Error calling setupAccount endpoint: $e');
      return false;
    }
  }

  // ✅ FIXED: Updated to save double values properly
  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get user ID to create user-specific keys
      final userId = prefs.getInt('id') ?? 0;
      
      print('🔄 Completing onboarding...');
      print('🔄 User ID: $userId');
      print('📊 User Data Debug: ${userData.toDebugString()}');

      if (userId == 0) {
        print('❌ Error: No valid user ID found');
        _showErrorDialog('Session error. Please login again.');
        return;
      }

      // Update onboarding status in database first
      print('🔄 Updating onboarding status in database...');
      final dbUpdateSuccess = await _updateOnboardingStatusInDatabase();
      
      if (!dbUpdateSuccess) {
        _showErrorDialog('Failed to complete setup. Please check your connection and try again.');
        return;
      }

      // Set onboarding_completed flags
      await prefs.setBool('onboarding_completed_$userId', true);
      await prefs.setBool('completedOnboarding', true);
      
      print('✅ Onboarding completed successfully for user $userId');
      
      // ✅ FIXED: Direct double values, no conversion needed
      final heightValue = userData.height;
      final weightValue = userData.weight;
      final goalWeightValue = userData.goalWeight;
      
      // Validate values
      if (heightValue <= 0 || weightValue <= 0) {
        _showErrorDialog('Invalid height or weight values. Please check your input.');
        return;
      }
      
      print('💾 Saving data to SharedPreferences...');
      print('   - Height: $heightValue (${heightValue.runtimeType})');
      print('   - Weight: $weightValue (${weightValue.runtimeType})');
      print('   - Goal Weight: $goalWeightValue (${goalWeightValue.runtimeType})');
      
      // ✅ FIXED: Save as double using setDouble method
      // Save onboarding data with user-specific keys
      await prefs.setString('gender_$userId', userData.gender);
      await prefs.setDouble('height_$userId', heightValue);
      await prefs.setDouble('weight_$userId', weightValue);
      await prefs.setDouble('goalWeight_$userId', goalWeightValue);
      
      // Save activity level as int
      if (userData.activityLevel != null) {
        await prefs.setInt('activityLevel_$userId', userData.activityLevel!);
      }
      
      await prefs.setString('heightUnit_$userId', userData.heightUnit ?? 'cm');
      await prefs.setString('weightUnit_$userId', userData.weightUnit ?? 'kg');
      
      // Save birth date if available
      if (userData.birthDate != null) {
        await prefs.setString('birthDate_$userId', userData.birthDate!.toIso8601String());
      }
      if (userData.birthDay != null) await prefs.setInt('birthDay_$userId', userData.birthDay!);
      if (userData.birthMonth != null) await prefs.setInt('birthMonth_$userId', userData.birthMonth!);
      if (userData.birthYear != null) await prefs.setInt('birthYear_$userId', userData.birthYear!);

      // ✅ FIXED: Update global data for compatibility - using setDouble
      await prefs.setString('gender', userData.gender);
      await prefs.setDouble('height', heightValue);
      await prefs.setDouble('weight', weightValue);
      await prefs.setDouble('goalWeight', goalWeightValue);
      
      // Save activity level as int globally too
      if (userData.activityLevel != null) {
        await prefs.setInt('activityLevel', userData.activityLevel!);
      }
      
      await prefs.setString('heightUnit', userData.heightUnit ?? 'cm');
      await prefs.setString('weightUnit', userData.weightUnit ?? 'kg');
      
      // Save birth date consistently
      if (userData.birthDate != null) {
        await prefs.setString('dateOfBirth', userData.birthDate!.toIso8601String().split('T')[0]);
        await prefs.setString('birthDate', userData.birthDate!.toIso8601String());
      }
      if (userData.birthDay != null) await prefs.setInt('birthDay', userData.birthDay!);
      if (userData.birthMonth != null) await prefs.setInt('birthMonth', userData.birthMonth!);
      if (userData.birthYear != null) await prefs.setInt('birthYear', userData.birthYear!);

      // Save firstName to full_name for consistency with login
      if (userData.firstName.isNotEmpty) {
        await prefs.setString('full_name', userData.firstName);
        await prefs.setString('username_$userId', userData.firstName);
      }

      print('✅ All data saved successfully to SharedPreferences');
      
      // Verify saved data
      print('🔍 Verifying saved data:');
      print('   - Height saved: ${prefs.getDouble('height')} (${prefs.getDouble('height').runtimeType})');
      print('   - Weight saved: ${prefs.getDouble('weight')} (${prefs.getDouble('weight').runtimeType})');
      print('   - Goal Weight saved: ${prefs.getDouble('goalWeight')} (${prefs.getDouble('goalWeight').runtimeType})');

      // Show success dialog
      if (context.mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('❌ Error completing onboarding: $e');
      _showErrorDialog('Something went wrong. Please try again.');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 71, 82, 145),
        title: Text(
          'Setup Complete!',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Welcome ${userData.firstName.isNotEmpty ? userData.firstName : 'User'}! Your profile has been set up successfully.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.white),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.of(context).pop();

              final prefs = await SharedPreferences.getInstance();
              final username = prefs.getString('full_name') ?? 'User';

              Navigator.pushReplacementNamed(
                context,
                '/home',
                arguments: {'userName': username},
              );
            },
            child: Text('Start Using App'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 71, 82, 145),
        title: Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.white),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Extension for debugging UserData
extension UserDataDebug on UserData {
  String toDebugString() {
    return '''
    - firstName: $firstName
    - gender: $gender
    - height: $height ($heightUnit) [${height.runtimeType}]
    - weight: $weight ($weightUnit) [${weight.runtimeType}]
    - goalWeight: $goalWeight [${goalWeight.runtimeType}]
    - activityLevel: $activityLevel
    - birthDay: $birthDay
    - birthMonth: $birthMonth
    - birthYear: $birthYear
    - birthDate: $birthDate
    - age: $age
    - bmi: $bmi
    - bmiCategory: $bmiCategory
    - hasValidPersonalInfo: $hasValidPersonalInfo
    - hasCompleteBodyMeasurements: $hasCompleteBodyMeasurements
    - hasValidActivityLevel: $hasValidActivityLevel
    ''';
  }
}