import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/progress_bar.dart';
import '../widgets/next_button.dart';
import 'pages/intro_screen.dart';
import 'pages/meal_planning_page.dart';
import 'pages/healthy_habits_page.dart';
import 'pages/weekly_meal_plan_page.dart';
import 'pages/goals_page.dart';
import 'pages/activity_level_page.dart';
import 'pages/personal_info_page.dart';
import 'pages/weekly_goal_page.dart';

class OnboardingFlow extends StatefulWidget {
  @override
  _OnboardingFlowState createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  PageController _pageController = PageController();
  int currentPage = 0;
  UserData userData = UserData();

  final List<String> pageTitles = [
    'Welcome',
    'Goals',
    'Goals',
    'Goals',
    'Goals',
    'Goals',
    'You',
    'Goal',
  ];

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
              totalSteps: 8,
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
                  WelcomePage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  MealPlanningPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  HealthyHabitsPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  WeeklyMealPlanPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  GoalsPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  ActivityLevelPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  PersonalInfoPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                  WeeklyGoalPage(
                    userData: userData,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
            NextButton(
              isEnabled: _canProceed(),
              isLastPage: currentPage == 7,
              onPressed: _nextPage,
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (currentPage) {
      case 0:
        return userData.firstName.isNotEmpty;
      case 1:
        return userData.mealPlanningFrequency.isNotEmpty;
      case 2:
        return userData.selectedHabits.isNotEmpty;
      case 3:
        return userData.wantsWeeklyMealPlan != null;
      case 4:
        return userData.selectedGoals.isNotEmpty;
      case 5:
        return userData.activityLevel != null &&
            userData.activityLevel!.isNotEmpty;
      case 6:
        return userData.gender.isNotEmpty &&
            userData.age != null &&
            userData.age! > 0;
      case 7:
        return userData.weeklyGoal.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (currentPage < 7) {
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

  void _completeOnboarding() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Color.fromARGB(255, 71, 82, 145),
      title: Text(
        'Setup Complete!',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        'Welcome ${userData.firstName}! Your profile has been set up successfully.',
        style: TextStyle(color: Colors.grey[300]),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1), // Background tombol
            foregroundColor: Colors.white, // Warna teks
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(color: Colors.white), // Border putih
            elevation: 0, // Tanpa bayangan
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Start Using App'),
        ),
      ],
    ),
  );
}

}


