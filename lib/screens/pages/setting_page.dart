import 'package:aplikasi_counting_calories/screens/pages/edit_profile_page.dart';
import 'package:aplikasi_counting_calories/service/deactive_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  bool _isLoading = false;
  String _userName = ' ';
  String _userEmail = ' ';
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

  // Auto refresh variables
  Timer? _refreshTimer;
  Timer? _updateTimer; // Timer untuk update UI setiap detik
  StreamSubscription<void>? _refreshStreamSubscription;
  final StreamController<void> _refreshStreamController = StreamController<void>.broadcast();
  static const Duration _refreshInterval = Duration(seconds: 1); // Refresh data setiap 30 detik
  static const Duration _updateInterval = Duration(seconds: 1); // Update UI setiap 1 detik
  bool _isAutoRefreshEnabled = true;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _startAutoRefresh();
    _startUpdateTimer(); // Start timer untuk update UI
    _setupRefreshListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoRefresh();
    _stopUpdateTimer(); // Stop timer untuk update UI
    _refreshStreamSubscription?.cancel();
    _refreshStreamController.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed - Starting auto refresh');
        _startAutoRefresh();
        _startUpdateTimer();
        _loadUserData();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        print('📱 App paused/inactive - Stopping auto refresh');
        _stopAutoRefresh();
        _stopUpdateTimer();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopAutoRefresh();
        _stopUpdateTimer();
        break;
    }
  }

  // Setup listener untuk manual refresh
  void _setupRefreshListener() {
    _refreshStreamSubscription = _refreshStreamController.stream.listen((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  // Start auto refresh timer untuk data
  void _startAutoRefresh() {
    if (!_isAutoRefreshEnabled) return;
    
    _stopAutoRefresh(); // Stop existing timer jika ada
    
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted && _isAutoRefreshEnabled) {
        print('🔄 Auto refreshing user data...');
        _loadUserData();
      } else {
        timer.cancel();
      }
    });
    
    print('✅ Auto refresh started (interval: ${_refreshInterval.inSeconds}s)');
  }

  // Start timer untuk update UI setiap detik
  void _startUpdateTimer() {
    _stopUpdateTimer(); // Stop existing timer jika ada
    
    _updateTimer = Timer.periodic(_updateInterval, (timer) {
      if (mounted) {
        setState(() {
          // Trigger rebuild untuk update tampilan waktu
        });
      } else {
        timer.cancel();
      }
    });
    
    print('✅ Update timer started (interval: ${_updateInterval.inSeconds}s)');
  }

  // Stop auto refresh timer
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    print('🛑 Auto refresh stopped');
  }

  // Stop update timer
  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
    print('🛑 Update timer stopped');
  }

  // Toggle auto refresh
  void _toggleAutoRefresh() {
    setState(() {
      _isAutoRefreshEnabled = !_isAutoRefreshEnabled;
    });
    
    if (_isAutoRefreshEnabled) {
      _startAutoRefresh();
      print('✅ Auto refresh enabled');
    } else {
      _stopAutoRefresh();
      print('🛑 Auto refresh disabled');
    }
  }

  // Manual refresh method
  Future<void> _manualRefresh() async {
    print('🔄 Manual refresh triggered');
    await _loadUserData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (mounted) {
        setState(() {
          // Get the current user ID first
          final userId = prefs.getInt('id') ?? 0;
          
          // Load basic user information
          _userName = prefs.getString('full_name') ?? 
                     prefs.getString('username_$userId') ?? 
                     prefs.getString('username') ?? 
                     'User';
          
          _userEmail = prefs.getString('email') ?? '';
          
          // Load additional user data
          final userDateOfBirth = prefs.getString('dateOfBirth') ?? '';
          final userGender = prefs.getString('gender') ?? '';
          final userHeight = prefs.getDouble('height') ?? 0.0;
          final userActivityLevel = prefs.getInt('activityLevel') ?? 0;
          final userActive = prefs.getBool('active') ?? false;
          final userProfileImage = prefs.getString('profileImage') ?? '';
          
          // Load session data
          final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
          final completedOnboarding = prefs.getBool('completedOnboarding') ?? false;
          final authToken = prefs.getString('auth_token') ?? '';
          
          // Assign to class variables
          _userId = userId;
          _userDateOfBirth = userDateOfBirth;
          _userGender = userGender;
          _userHeight = userHeight;
          _userActivityLevel = userActivityLevel;
          _userActive = userActive;
          _userProfileImage = userProfileImage;
          _isLoggedIn = isLoggedIn;
          _completedOnboarding = completedOnboarding;
          _authToken = authToken;
          
          // Update last refresh time
          _lastRefreshTime = DateTime.now();
        });
      }

      // Debug print
      print('🔍 === LOADING ALL USER DATA ===');
      print('🔍 Refresh Time: ${_lastRefreshTime?.toString()}');
      print('🔍 User ID: ${prefs.getInt('id')}');
      print('🔍 Full Name: ${prefs.getString('full_name')}');
      print('🔍 Email: ${prefs.getString('email')}');
      print('🔍 Auto Refresh: ${_isAutoRefreshEnabled ? 'ON' : 'OFF'}');
      print('🔍 ===============================');
      
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    
    // Stop auto refresh saat logout
    _stopAutoRefresh();
    _stopUpdateTimer();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('id') ?? 0;
      print('🔄 Logging out user ID: $userId');
      
      // Clear user data
      await prefs.remove('isLoggedIn');
      await prefs.remove('id');
      await prefs.remove('full_name');
      await prefs.remove('email');
      await prefs.remove('created_at');
      await prefs.remove('dateOfBirth');
      await prefs.remove('auth_token');
      await prefs.remove('gender');
      await prefs.remove('height');
      await prefs.remove('weight');
      await prefs.remove('activityLevel');
      await prefs.remove('active');
      await prefs.remove('profileImage');
      await prefs.remove('goalWeight');
      await prefs.remove('heightUnit');
      await prefs.remove('weightUnit');
      await prefs.remove('birthDate');
      await prefs.remove('birthDay');
      await prefs.remove('birthMonth');
      await prefs.remove('birthYear');
      
      print('✅ Session cleared for user $userId');
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount(String password) async {
    if (!mounted) return;
    
    // Stop auto refresh saat delete account
    _stopAutoRefresh();
    _stopUpdateTimer();
    
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      print('🔍 Debug Password Info:');
      print('   Password length: ${password.length}');
      print('   Password trimmed length: ${password.trim().length}');
      
      if (!DeactiveService.isValidPassword(password)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password must be at least 6 characters long'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('🔄 Calling deactivate service...');
      final result = await DeactiveService.deactivateAccount(password);
      print('🔄 Deactivate result: $result');

      bool isSuccessful = _isDeactivationSuccessful(result);

      if (isSuccessful) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Account deactivated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }

        await Future.delayed(Duration(seconds: 2));

        if (mounted) {
          print('🔄 Navigating to login page...');
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          String errorMessage = _getErrorMessage(result);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  _showDeleteAccountDialog();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Unexpected error in _deleteAccount: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
        // Restart auto refresh jika masih di halaman ini dan enabled
        if (_isAutoRefreshEnabled) {
          _startAutoRefresh();
          _startUpdateTimer();
        }
      }
    }
  }

  bool _isDeactivationSuccessful(Map<String, dynamic> result) {
    if (result['success'] == true) {
      return true;
    }
    
    if (result['message'] != null) {
      String message = result['message'].toString().toLowerCase();
      List<String> successIndicators = [
        'successful',
        'success',
        'deactivated',
        'deleted',
        'removed',
        'account deactivation successful',
      ];
      
      for (String indicator in successIndicators) {
        if (message.contains(indicator)) {
          return true;
        }
      }
    }
    
    return false;
  }

  String _getErrorMessage(Map<String, dynamic> result) {
    String errorMessage = result['message'] ?? 'Failed to deactivate account';
    
    if (errorMessage.toLowerCase().contains('password')) {
      return 'Incorrect password. Please check your password and try again.';
    } else if (errorMessage.toLowerCase().contains('unauthorized')) {
      return 'Session expired. Please login again and try.';
    } else if (errorMessage.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    
    return errorMessage;
  }

  void _showDeleteAccountDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DeleteAccountDialog(
          isDeletingAccount: _isDeletingAccount,
          onDeleteAccount: _deleteAccount,
        );
      },
    );
  }

  void _showLogoutDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D44),
          title: Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _manualRefresh,
      color: Colors.blue,
      backgroundColor: Color(0xFF2D2D44),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileCard(),
                  SizedBox(height: 24),
                  _buildPreferencesSection(),
                  SizedBox(height: 24),
                  _buildAccountSection(),
                  SizedBox(height: 24),
                  _buildHelpSection(),
                  SizedBox(height: 32),
                  _buildLogoutButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(),
                    ),
                  );
                  
                  // Refresh data setelah kembali dari edit profile
                  if (result != null || result == true) {
                    _loadUserData();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Last refresh info dengan real-time update
          
        ],
      ),
    );
  }


  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Preferences',
      children: [
        _buildSettingItem(
          icon: Icons.restaurant_outlined,
          title: 'Edit Nutrition Goal',
          subtitle: 'Customize your daily nutrition targets',
          onTap: () {},
        ),
        SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.directions_run_outlined,
          title: 'Activity Level',
          subtitle: 'Set your daily activity level',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      children: [
        _buildSettingItem(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          onTap: _showDeleteAccountDialog,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & FAQ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Get help and find answers',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final bool isDeletingAccount;
  final Function(String) onDeleteAccount;

  const _DeleteAccountDialog({
    required this.isDeletingAccount,
    required this.onDeleteAccount,
  });

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late TextEditingController _passwordController;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF2D2D44),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone. Your account will be permanently deactivated.',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Enter your password to confirm:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isDeletingAccount
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: widget.isDeletingAccount
              ? null
              : () {
                  if (_passwordController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Please enter your password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final password = _passwordController.text.trim();
                  Navigator.of(context).pop();
                  widget.onDeleteAccount(password);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: widget.isDeletingAccount
              ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}