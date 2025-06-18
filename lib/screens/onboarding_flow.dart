import 'package:aplikasi_counting_calories/screens/pages/body_measure_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/progress_bar.dart';
import 'pages/activity_level_page.dart';
import 'pages/personal_info_page.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  PageController _pageController = PageController();
  int currentPage = 0;
  UserData userData = UserData();

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
                  Column(
                    children: [
                      Expanded(
                        child: ActivityLevelPage(
                          userData: userData,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      // Temporary NextButton untuk ActivityLevelPage
                      _buildNextButton(
                        isEnabled: userData.hasValidActivityLevel,
                        isLastPage: true,
                        onPressed: _completeOnboarding,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Temporary NextButton widget (hanya untuk ActivityLevelPage sekarang)
  Widget _buildNextButton({
    required bool isEnabled,
    required bool isLastPage,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 50), 
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            disabledBackgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: Text(
            isLastPage ? 'Get Started' : 'Next',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  Future<void> _completeOnboarding() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ PERBAIKAN: Ambil user ID untuk membuat key yang spesifik per user
    final userId = prefs.getInt('id') ?? 0;
    
    print('🔄 Completing onboarding...');
    print('🔄 User ID: $userId');
    print('📊 User Data Debug: ${userData.toDebugString()}');

    if (userId == 0) {
      print('❌ Error: No valid user ID found');
      _showErrorDialog('Session error. Please login again.');
      return;
    }

    // ✅ PERBAIKAN: Set onboarding_completed berdasarkan user ID
    await prefs.setBool('onboarding_completed_$userId', true);
    
    print('✅ Onboarding completed successfully for user $userId');
    print('✅ onboarding_completed_$userId set to true');
    
    // Simpan data onboarding dengan user-specific keys juga (opsional)
    await prefs.setString('gender_$userId', userData.gender);
    await prefs.setString('height_$userId', userData.height);
    await prefs.setString('weight_$userId', userData.weight);
    await prefs.setString('goalWeight_$userId', userData.goalWeight);
    await prefs.setString('activityLevel_$userId', userData.activityLevel ?? '');
    await prefs.setString('heightUnit_$userId', userData.heightUnit ?? 'cm');
    await prefs.setString('weightUnit_$userId', userData.weightUnit ?? 'kg');
    
    // Simpan birth date jika ada
    if (userData.birthDate != null) {
      await prefs.setString('birthDate_$userId', userData.birthDate!.toIso8601String());
    }
    if (userData.birthDay != null) await prefs.setInt('birthDay_$userId', userData.birthDay!);
    if (userData.birthMonth != null) await prefs.setInt('birthMonth_$userId', userData.birthMonth!);
    if (userData.birthYear != null) await prefs.setInt('birthYear_$userId', userData.birthYear!);

    // JUGA update data global untuk kompatibilitas (opsional)
    await prefs.setString('gender', userData.gender);
    await prefs.setString('height', userData.height);
    await prefs.setString('weight', userData.weight);
    await prefs.setString('goalWeight', userData.goalWeight);
    await prefs.setString('activityLevel', userData.activityLevel ?? '');
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

// Extension untuk debug UserData
extension UserDataDebug on UserData {
  String toDebugString() {
    return '''
    UserData Debug:
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