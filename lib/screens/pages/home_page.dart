import 'dart:async';
import 'package:aplikasi_counting_calories/screens/pages/food_scan_page.dart';
import 'package:aplikasi_counting_calories/screens/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_counting_calories/screens/pages/setting_page.dart';
import 'package:aplikasi_counting_calories/widgets/navigation_bar_bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationWrapper extends StatefulWidget {
  final String userName;
  
  const MainNavigationWrapper({Key? key, this.userName = 'User'}) : super(key: key);

  @override
  _MainNavigationWrapperState createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int currentIndex = 0;
  String userName = 'User';
  bool _isLoading = false;
  String _userName = 'User';
  String _userEmail = '';
  bool _isMetric = true;
  bool _isDeletingAccount = false;
  int _userId = 0;
  String _userDateOfBirth = '';
  String _userGender = '';
  double _userHeight = 0.0;
  double _userWeight = 0.0;
  int _userActivityLevel = 0;
  bool _userActive = false;
  String _userProfileImage = '';
  bool _isLoggedIn = false;
  bool _completedOnboarding = false;
  String _authToken = '';

  // Auto-refresh variables
  Timer? _refreshTimer;
  String? _lastUpdateTimestamp;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _checkForProfileUpdates();
    });
  }

  Future<void> _checkForProfileUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString('last_profile_update');
      
      if (lastUpdate != null && lastUpdate != _lastUpdateTimestamp) {
        _lastUpdateTimestamp = lastUpdate;
        await _loadUserData();
        print('🔄 Profile data refreshed due to update detected');
      }
    } catch (e) {
      print('❌ Error checking for profile updates: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (mounted) {
        setState(() {
          // Get the current user ID first
          final userId = prefs.getInt('id') ?? 0;
          
          // Load basic user information with multiple fallbacks
          _userName = prefs.getString('full_name') ?? 
                     prefs.getString('username_$userId') ?? 
                     prefs.getString('username') ?? 
                     widget.userName;
          
          _userEmail = prefs.getString('email') ?? '';
          
          // Load additional user data
          _userDateOfBirth = prefs.getString('dateOfBirth') ?? '';
          _userGender = prefs.getString('gender') ?? '';
          _userHeight = prefs.getDouble('height') ?? 0.0;
          _userWeight = prefs.getDouble('weight') ?? 0.0;
          _userActivityLevel = prefs.getInt('activityLevel') ?? 0;
          _userActive = prefs.getBool('active') ?? false;
          _userProfileImage = prefs.getString('profileImage') ?? '';
          
          // Load session data
          _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          _completedOnboarding = prefs.getBool('completedOnboarding') ?? false;
          _authToken = prefs.getString('auth_token') ?? '';
          
          // Assign to class variables
          _userId = userId;
          
          // Update userName for backward compatibility
          userName = _userName;
        });
      }

      // Debug print to verify all data loading
      print('🔍 === LOADING ALL USER DATA ===');
      print('🔍 User ID: ${prefs.getInt('id')}');
      print('🔍 Full Name: ${prefs.getString('full_name')}');
      print('🔍 Username: ${prefs.getString('username_${prefs.getInt('id')}')}');
      print('🔍 Username (fallback): ${prefs.getString('username')}');
      print('🔍 Final Username: $_userName');
      print('🔍 Email: ${prefs.getString('email')}');
      print('🔍 Created At: ${prefs.getString('created_at')}');
      print('🔍 Date of Birth: ${prefs.getString('dateOfBirth')}');
      print('🔍 Gender: ${prefs.getString('gender')}');
      print('🔍 Height: ${prefs.getDouble('height')}');
      print('🔍 Weight: ${prefs.getDouble('weight')}');
      print('🔍 Activity Level: ${prefs.getInt('activityLevel')}');
      print('🔍 Active: ${prefs.getBool('active')}');
      print('🔍 Profile Image: ${prefs.getString('profileImage')}');
      print('🔍 Is Logged In: ${prefs.getBool('isLoggedIn')}');
      print('🔍 Completed Onboarding: ${prefs.getBool('completedOnboarding')}');
      print('🔍 Auth Token: ${prefs.getString('auth_token') != null ? '[TOKEN EXISTS]' : 'null'}');
      print('🔍 Last Profile Update: ${prefs.getString('last_profile_update')}');
      print('🔍 All Available Keys: ${prefs.getKeys().toList()}');
      print('🔍 ===============================');
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      currentIndex = index;
    });
    
    // Refresh data ketika kembali ke homepage
    if (index == 0) {
      Future.delayed(Duration(milliseconds: 100), () {
        _loadUserData();
      });
    }
  }

  Widget _getCurrentPage() {
    switch (currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return FoodScanPage();
      case 2:
        return HistoryPage();
      case 3:
        return SettingsPage();
      default:
        return _buildHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: _getCurrentPage(),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildTodaySection(),
          const SizedBox(height: 20),
          _buildCaloriesCard(),
          const SizedBox(height: 20),
          _buildFoodSuggestionCard(),
          const SizedBox(height: 30),
          _buildDailyLogsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_getGreeting()}, ',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _getGreetingEmoji(),
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            Text(
              _userName.isNotEmpty ? _userName : 'User',
              style: TextStyle(
                color: Colors.blue[300],
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Debug info (remove in production)
            if (_userName.isEmpty)
              Text(
                'Debug: Username is empty',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    
    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  Widget _buildTodaySection() {
    return Text(
      'Today',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCaloriesCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                _buildCalorieItem('Base Goal', '2,200', Icons.flag_outlined),
                SizedBox(height: 12),
                _buildCalorieItem('Consumed', '1,007', Icons.local_fire_department_outlined),
              ],
            ),
          ),
          SizedBox(width: 20),
          _buildCalorieCircle(),
        ],
      ),
    );
  }

  Widget _buildCalorieItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalorieCircle() {
    return Container(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 0.45,
              strokeWidth: 8,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1,193',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Remaining',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSuggestionCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Food Suggestion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'For Dinner',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                'Beef Salad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Spacer(),
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '+800 kcal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyLogsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildMealSection('Breakfast'),
                _buildFoodItem('Nasi Goreng', '7:30 AM', '+343 kcal'),
                SizedBox(height: 16),
                _buildMealSection('Lunch'),
                _buildFoodItem('Nasi Padang', '12:45 PM', '+664 kcal'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(String mealType) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Text(
            mealType,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(String foodName, String time, String calories) {
    return Container(
      margin: EdgeInsets.only(left: 20, bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  foodName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            calories,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage(String pageName) {
    return Center(
      child: Text(
        '$pageName - Coming Soon',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}