import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  String _userName = 'User';
  String _userEmail = 'usermail@mail.com';
  bool _isMetric = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? 'User';
      _userEmail = prefs.getString('email') ?? 'usermail@mail.com';
    });
  }

  Future<void> _logout() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    
    // ✅ Ambil user ID sebelum menghapus session
    final userId = prefs.getInt('id') ?? 0;
    print('🔄 Logging out user ID: $userId');
    
    // ✅ Hapus hanya session data, BUKAN user-specific data seperti onboarding status
    await prefs.remove('isLoggedIn');
    await prefs.remove('id');
    await prefs.remove('full_name');
    await prefs.remove('email');
    await prefs.remove('created_at');
    await prefs.remove('dateOfBirth');
    await prefs.remove('auth_token');
    
    // Hapus data global (yang akan di-replace ketika user lain login)
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
    print('✅ User-specific onboarding data preserved');
    
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error logging out: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showLogoutDialog() {
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
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    SizedBox(height: 20),
                    _buildPreferencesSection(),
                    SizedBox(height: 20),
                    _buildAccountSection(),
                    SizedBox(height: 20),
                    _buildUnitSection(),
                    SizedBox(height: 20),
                    _buildHelpSection(),
                    SizedBox(height: 20),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            'Settings',
            style: TextStyle(
              color: Colors.blue[300],
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🇺🇸',
              style: TextStyle(fontSize: 16),
            ),
          ),
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
      child: Row(
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
          Container(
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
          onTap: () {
            // Navigate to nutrition goal page
          },
        ),
        _buildSettingItem(
          icon: Icons.directions_run_outlined,
          title: 'Activity Level',
          subtitle: 'Set your daily activity level',
          onTap: () {
            // Navigate to activity level page
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Account',
      children: [
        _buildSettingItem(
          icon: Icons.tune_outlined,
          title: 'Calibration',
          subtitle: 'Adjust app settings for accuracy',
          onTap: () {
            // Navigate to calibration page
          },
        ),
        _buildSettingItem(
          icon: Icons.download_outlined,
          title: 'Export My Data',
          subtitle: 'Download your personal data',
          onTap: () {
            // Export data functionality
          },
        ),
        _buildSettingItem(
          icon: Icons.delete_outline,
          title: 'Delete Account',
          subtitle: 'Permanently delete your account',
          onTap: () {
            // Show delete account dialog
          },
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildUnitSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
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
              Icons.straighten_outlined,
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
                  'Unit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Choose measurement system',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMetric = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isMetric ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Metric',
                      style: TextStyle(
                        color: _isMetric ? Colors.white : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isMetric = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_isMetric ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Imperial',
                      style: TextStyle(
                        color: !_isMetric ? Colors.white : Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return _buildSettingItem(
      icon: Icons.help_outline,
      title: 'Help & FAQ',
      subtitle: 'Get help and find answers',
      onTap: () {
        // Navigate to help page
      },
      showContainer: true,
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
          ...children.map((child) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: child,
              )),
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
    bool showContainer = false,
  }) {
    Widget content = Row(
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
    );

    if (showContainer) {
      content = Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(16),
        ),
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }
}