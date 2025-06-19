import 'package:aplikasi_counting_calories/screens/pages/body_measure_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isLoading = false; // Add loading state

  // Updated to match actual pages in correct order
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
                  // ✅ FIXED: Use ActivityLevelPage without external button
                  ActivityLevelPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                    onNext: _saveActivityLevelAndComplete, // ✅ FIXED: Custom callback
                    showNextButton: true, // ✅ Use internal ActivityLevelPage button
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

  // ✅ FIXED: Function specifically for saving activity level and completing onboarding
  Future<void> _saveActivityLevelAndComplete() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting save activity level and complete onboarding...');
      
      // ✅ FIXED: Validate activity level (now int instead of string)
      if (userData.activityLevel == null) {
        throw Exception('Please select an activity level');
      }

      // ✅ FIXED: Activity level is already an integer, no conversion needed
      int activityLevelValue = userData.activityLevel!;
      
      if (activityLevelValue < 1 || activityLevelValue > 5) {
        throw Exception('Invalid activity level selected');
      }

      print('📊 Activity level integer: $activityLevelValue');

      // ✅ FIXED: Save activity level to database
      final result = await ActivityLevelService.updateActivityLevel(
        activityLevel: activityLevelValue,
      );

      print('🔄 Activity level service result: $result');

      if (result['success']) {
        print('✅ Activity level saved to database successfully');
        
        // ✅ FIXED: Complete onboarding after successful save
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

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ FIXED: Get user ID to create user-specific keys
      final userId = prefs.getInt('id') ?? 0;
      
      print('🔄 Completing onboarding...');
      print('🔄 User ID: $userId');
      print('📊 User Data Debug: ${userData.toDebugString()}');

      if (userId == 0) {
        print('❌ Error: No valid user ID found');
        _showErrorDialog('Session error. Please login again.');
        return;
      }

      // ✅ FIXED: Set onboarding_completed based on user ID
      await prefs.setBool('onboarding_completed_$userId', true);
      
      print('✅ Onboarding completed successfully for user $userId');
      print('✅ onboarding_completed_$userId set to true');
      
      // Save onboarding data with user-specific keys (optional)
      await prefs.setString('gender_$userId', userData.gender);
      await prefs.setString('height_$userId', userData.height);
      await prefs.setString('weight_$userId', userData.weight);
      await prefs.setString('goalWeight_$userId', userData.goalWeight);
      
      // ✅ FIXED: Save activity level as int (convert to string for SharedPreferences)
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

      // ALSO update global data for compatibility (optional)
      await prefs.setString('gender', userData.gender);
      await prefs.setString('height', userData.height);
      await prefs.setString('weight', userData.weight);
      await prefs.setString('goalWeight', userData.goalWeight);
      
      // ✅ FIXED: Save activity level as int globally too
      if (userData.activityLevel != null) {
        await prefs.setInt('activityLevel', userData.activityLevel!);
      }
      
      await prefs.setString('heightUnit', userData.heightUnit ?? 'cm');
      await prefs.setString('weightUnit', userData.weightUnit ?? 'kg');
      
      if (userData.birthDate != null) {
        await prefs.setString('birthDate', userData.birthDate!.toIso8601String());
      }
      if (userData.birthDay != null) await prefs.setInt('birthDay', userData.birthDay!);
      if (userData.birthMonth != null) await prefs.setInt('birthMonth', userData.birthMonth!);
      if (userData.birthYear != null) await prefs.setInt('birthYear', userData.birthYear!);

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
    - height: $height ($heightUnit)
    - weight: $weight ($weightUnit)
    - goalWeight: $goalWeight
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