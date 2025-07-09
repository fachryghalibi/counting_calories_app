import 'dart:async';
import 'package:aplikasi_counting_calories/screens/pages/food_scan_page.dart';
import 'package:aplikasi_counting_calories/screens/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_counting_calories/screens/pages/setting_page.dart';
import 'package:aplikasi_counting_calories/widgets/navigation_bar_bottom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigationWrapper extends StatefulWidget {
  final String userName;

  const MainNavigationWrapper({Key? key, this.userName = 'User'})
      : super(key: key);

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
      print(
          '🔍 Username: ${prefs.getString('username_${prefs.getInt('id')}')}');
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
      print(
          '🔍 Auth Token: ${prefs.getString('auth_token') != null ? '[TOKEN EXISTS]' : 'null'}');
      print(
          '🔍 Last Profile Update: ${prefs.getString('last_profile_update')}');
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

  Widget _buildBMICard() {
    String bmiValue = _calculateBMI();
    Color bmiColor = _getBMIColor();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bmiColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bmiColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assessment,
                  color: bmiColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Body Mass Index (BMI)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      bmiValue,
                      style: TextStyle(
                        color: bmiColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildBMIScale(),
        ],
      ),
    );
  }

  Widget _buildBMIScale() {
    double currentBMI = 0;
    if (_userHeight > 0 && _userWeight > 0) {
      double heightInMeters = _userHeight / 100;
      currentBMI = _userWeight / (heightInMeters * heightInMeters);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                    ],
                    stops: [0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('18.5',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('25', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('30', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text('35+',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Under',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            Text('Normal',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            Text('Over',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            Text('Obese',
                style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.green[300],
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Health Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildBMICard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
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
    );
  }


  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: Colors.purple[300],
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Scan Food',
                  Icons.camera_alt,
                  Colors.green,
                  () => setState(() => currentIndex = 1),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'View History',
                  Icons.history,
                  Colors.blue,
                  () => setState(() => currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInsights() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2D2D44),
          Color(0xFF1A1A2E),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[300],
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Personalized tips based on your profile',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        
        // Main insight card
        _buildMainInsightCard(),
        
        SizedBox(height: 16),
        
        // Secondary insights
        Row(
          children: [
            Expanded(
              child: _buildSecondaryInsightCard(
                _getHydrationInsight(),
                Icons.water_drop,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryInsightCard(
                _getActivityInsight(),
                Icons.directions_run,
                Colors.green,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Food recommendations
        _buildFoodRecommendations(),
      ],
    ),
  );
}

Widget _buildMainInsightCard() {
  Map<String, dynamic> insight = _getMainInsight();
  
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: insight['color'].withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: insight['color'].withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              insight['icon'],
              color: insight['color'],
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                insight['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          insight['description'],
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (insight['tip'] != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.amber[300],
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight['tip'],
                    style: TextStyle(
                      color: Colors.amber[300],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _buildSecondaryInsightCard(Map<String, dynamic> insight, IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                insight['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          insight['message'],
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFoodRecommendations() {
  List<Map<String, dynamic>> recommendations = _getFoodRecommendations();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            Icons.restaurant,
            color: Colors.orange[300],
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Food Recommendations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: recommendations.map((food) {
            return Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    food['emoji'],
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 4),
                  Text(
                    food['name'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    food['benefit'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

// Helper methods for generating insights
Map<String, dynamic> _getMainInsight() {
  double bmi = 0;
  if (_userHeight > 0 && _userWeight > 0) {
    double heightInMeters = _userHeight / 100;
    bmi = _userWeight / (heightInMeters * heightInMeters);
  }
  
  String age = _calculateAge();
  int ageNumber = 0;
  if (age.contains('years')) {
    ageNumber = int.tryParse(age.split(' ')[0]) ?? 0;
  }
  
  // BMI-based insights
  if (bmi < 18.5) {
    return {
      'icon': Icons.trending_up,
      'color': Colors.blue,
      'title': 'Focus on Weight Gain',
      'description': 'Your BMI indicates you might benefit from healthy weight gain. Consider increasing your calorie intake with nutrient-dense foods.',
      'tip': 'Add healthy fats like avocados, nuts, and olive oil to your meals.',
    };
  } else if (bmi >= 30) {
    return {
      'icon': Icons.trending_down,
      'color': Colors.red,
      'title': 'Weight Management Focus',
      'description': 'A balanced calorie deficit with regular exercise can help you reach a healthier weight range.',
      'tip': 'Aim for 300-500 calorie deficit per day for sustainable weight loss.',
    };
  } else if (bmi >= 25) {
    return {
      'icon': Icons.balance,
      'color': Colors.orange,
      'title': 'Maintain Balanced Nutrition',
      'description': 'Focus on portion control and choosing nutrient-dense foods to maintain a healthy weight.',
      'tip': 'Fill half your plate with vegetables and fruits at each meal.',
    };
  }
  
  // Age-based insights
  if (ageNumber >= 50) {
    return {
      'icon': Icons.health_and_safety,
      'color': Colors.green,
      'title': 'Bone Health Priority',
      'description': 'At your age, calcium and vitamin D are crucial for bone health. Include dairy, leafy greens, and fortified foods.',
      'tip': 'Aim for 1200mg calcium and 800 IU vitamin D daily.',
    };
  } else if (ageNumber >= 30) {
    return {
      'icon': Icons.favorite,
      'color': Colors.red,
      'title': 'Heart Health Focus',
      'description': 'Prioritize heart-healthy foods like fish, nuts, and whole grains to maintain cardiovascular health.',
      'tip': 'Include omega-3 rich foods like salmon twice a week.',
    };
  }
  
  // Gender-based insights
  if (_userGender.toLowerCase() == 'female') {
    return {
      'icon': Icons.local_florist,
      'color': Colors.pink,
      'title': 'Iron & Folate Focus',
      'description': 'Women need more iron and folate. Include lean meats, beans, and leafy greens in your diet.',
      'tip': 'Pair iron-rich foods with vitamin C to enhance absorption.',
    };
  }
  
  // Default insight
  return {
    'icon': Icons.psychology,
    'color': Colors.purple,
    'title': 'Balanced Nutrition',
    'description': 'Focus on a balanced diet with variety from all food groups for optimal health.',
    'tip': 'Aim for 5 servings of fruits and vegetables daily.',
  };
}

Map<String, dynamic> _getHydrationInsight() {
  double waterNeeded = _userWeight * 35; // ml per kg body weight
  
  return {
    'title': 'Hydration Goal',
    'message': _userWeight > 0 
        ? 'Drink ${(waterNeeded / 1000).toStringAsFixed(1)}L water daily'
        : 'Stay hydrated with 8 glasses of water daily',
  };
}

Map<String, dynamic> _getActivityInsight() {
  String activityLevel = _getActivityLevelText();
  
  Map<String, String> recommendations = {
    'Sedentary': 'Add 30 min walking daily',
    'Lightly Active': 'Great! Consider strength training',
    'Moderately Active': 'Perfect balance maintained',
    'Very Active': 'Ensure proper recovery',
    'Extra Active': 'Monitor for overtraining',
  };
  
  return {
    'title': 'Activity Level',
    'message': recommendations[activityLevel] ?? 'Stay active for better health',
  };
}

List<Map<String, dynamic>> _getFoodRecommendations() {
  double bmi = 0;
  if (_userHeight > 0 && _userWeight > 0) {
    double heightInMeters = _userHeight / 100;
    bmi = _userWeight / (heightInMeters * heightInMeters);
  }
  
  if (bmi < 18.5) {
    return [
      {'emoji': '🥑', 'name': 'Avocado', 'benefit': 'Healthy fats'},
      {'emoji': '🥜', 'name': 'Nuts', 'benefit': 'Protein & calories'},
      {'emoji': '🍌', 'name': 'Banana', 'benefit': 'Quick energy'},
      {'emoji': '🥛', 'name': 'Milk', 'benefit': 'Protein & calcium'},
    ];
  } else if (bmi >= 25) {
    return [
      {'emoji': '🥬', 'name': 'Leafy Greens', 'benefit': 'Low calorie'},
      {'emoji': '🐟', 'name': 'Fish', 'benefit': 'Lean protein'},
      {'emoji': '🫐', 'name': 'Berries', 'benefit': 'Antioxidants'},
      {'emoji': '🥒', 'name': 'Cucumber', 'benefit': 'Hydrating'},
    ];
  }
  
  // Default healthy recommendations
  return [
    {'emoji': '🥕', 'name': 'Carrots', 'benefit': 'Beta-carotene'},
    {'emoji': '🥚', 'name': 'Eggs', 'benefit': 'Complete protein'},
    {'emoji': '🍎', 'name': 'Apple', 'benefit': 'Fiber'},
    {'emoji': '🥦', 'name': 'Broccoli', 'benefit': 'Vitamins'},
  ];
}

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildProfileOverview(),
            const SizedBox(height: 20),
            _buildHealthMetrics(),
            const SizedBox(height: 20),
            _buildNutritionInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOverview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2D44),
            Color(0xFF1A1A2E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.blue[300],
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your health information at a glance',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildProfileInfoCard(
                  'Personal Info',
                  [
                    _buildInfoRow(
                        'Gender',
                        _userGender.isNotEmpty ? _userGender : 'Not specified',
                        Icons.person),
                    _buildInfoRow('Age', _calculateAge(), Icons.cake),
                    _buildInfoRow('Activity', _getActivityLevelText(),
                        Icons.directions_run),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildProfileInfoCard(
                  'Physical Stats',
                  [
                    _buildInfoRow(
                        'Height',
                        _userHeight > 0
                            ? '${_userHeight.toStringAsFixed(0)} cm'
                            : 'Not specified',
                        Icons.height),
                    _buildInfoRow(
                        'Weight',
                        _userWeight > 0
                            ? '${_userWeight.toStringAsFixed(1)} kg'
                            : 'Not specified',
                        Icons.monitor_weight),
                    _buildInfoRow('BMI', _calculateBMI(), Icons.assessment),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue[300],
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          ...children,
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

  String _calculateAge() {
    if (_userDateOfBirth.isEmpty) return 'Not specified';

    try {
      DateTime birthDate = DateTime.parse(_userDateOfBirth);
      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return '$age years old';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getActivityLevelText() {
    switch (_userActivityLevel) {
      case 1:
        return 'Sedentary';
      case 2:
        return 'Lightly Active';
      case 3:
        return 'Moderately Active';
      case 4:
        return 'Very Active';
      case 5:
        return 'Extra Active';
      default:
        return 'Not specified';
    }
  }

  String _calculateBMI() {
    if (_userHeight <= 0 || _userWeight <= 0) return 'Not available';

    double heightInMeters = _userHeight / 100;
    double bmi = _userWeight / (heightInMeters * heightInMeters);

    String status;
    if (bmi < 18.5) {
      status = 'Underweight';
    } else if (bmi < 25) {
      status = 'Normal';
    } else if (bmi < 30) {
      status = 'Overweight';
    } else {
      status = 'Obese';
    }

    return '${bmi.toStringAsFixed(1)} ($status)';
  }

  Color _getBMIColor() {
    if (_userHeight <= 0 || _userWeight <= 0) return Colors.grey;

    double heightInMeters = _userHeight / 100;
    double bmi = _userWeight / (heightInMeters * heightInMeters);

    if (bmi < 18.5) {
      return Colors.blue;
    } else if (bmi < 25) {
      return Colors.green;
    } else if (bmi < 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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
}