import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_counting_calories/service/edit_profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingUserData = true;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEditingPassword = false;

  String _originalUsername = '';
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load from SharedPreferences first
      String username = prefs.getString('username') ?? 
                       prefs.getString('full_name') ?? '';
      String email = prefs.getString('email') ?? '';

      // Try to get fresh data from API
      final result = await EditProfileService.getCurrentUser();
      
      if (result['success'] == true && result['data'] != null) {
        final userData = result['data'];
        username = userData['username'] ?? userData['full_name'] ?? username;
        email = userData['email'] ?? email;
      }

      if (mounted) {
        setState(() {
          _originalUsername = username;
          _originalEmail = email;
          _usernameController.text = username;
          _emailController.text = email;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
        _showSnackBar('Failed to load user data', isError: true);
      }
    }
  }

  /// Menyimpan data profil yang sudah diupdate ke SharedPreferences
  Future<void> _saveToSharedPreferences({
    String? username,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (username != null) {
        await prefs.setString('username', username);
        await prefs.setString('full_name', username); // Untuk kompatibilitas
        print('✅ Username saved to SharedPreferences: $username');
      }
      
      if (email != null) {
        await prefs.setString('email', email);
        print('✅ Email saved to SharedPreferences: $email');
      }
      
      // Simpan timestamp update terakhir
      await prefs.setString('last_profile_update', DateTime.now().toIso8601String());
      
    } catch (e) {
      print('❌ Error saving to SharedPreferences: $e');
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool hasChanges = false;
      String? newUsername;
      String? newEmail;

      // Check if username changed
      if (_usernameController.text.trim() != _originalUsername) {
        newUsername = _usernameController.text.trim();
        hasChanges = true;
      }

      // Check if email changed
      if (_emailController.text.trim() != _originalEmail) {
        newEmail = _emailController.text.trim();
        hasChanges = true;
      }

      if (!hasChanges) {
        _showSnackBar('No changes to save');
        return;
      }

      // Update user data ke server
      final result = await EditProfileService.updateUserData(
        username: newUsername,
        email: newEmail,
      );

      if (result['success'] == true) {
        // Update original values
        _originalUsername = newUsername ?? _originalUsername;
        _originalEmail = newEmail ?? _originalEmail;

        // Simpan ke SharedPreferences setelah berhasil update ke server
        await _saveToSharedPreferences(
          username: newUsername,
          email: newEmail,
        );

        _showSnackBar(result['message'] ?? 'Profile updated successfully');
        
        // Optional: Pop back to previous screen setelah berhasil save
        // Navigator.of(context).pop();
        
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update profile', isError: true);
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      _showSnackBar('An error occurred while saving', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Menyimpan informasi password update ke SharedPreferences (opsional)
  Future<void> _savePasswordUpdateInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_password_update', DateTime.now().toIso8601String());
      print('✅ Password update timestamp saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving password update info: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.trim().isEmpty) {
      _showSnackBar('Please enter your current password', isError: true);
      return;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      _showSnackBar('Please enter a new password', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (!EditProfileService.isValidPassword(_newPasswordController.text)) {
      _showSnackBar('Password must be at least 6 characters long', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await EditProfileService.updatePassword(
        oldPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (result['success'] == true) {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        setState(() {
          _isEditingPassword = false;
        });

        // Simpan informasi update password ke SharedPreferences
        await _savePasswordUpdateInfo();

        _showSnackBar(result['message'] ?? 'Password updated successfully');
      } else {
        _showSnackBar(result['message'] ?? 'Failed to update password', isError: true);
      }
    } catch (e) {
      print('❌ Error changing password: $e');
      _showSnackBar('An error occurred while changing password', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: _isLoadingUserData
          ? _buildLoadingWidget()
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Edit Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _saveProfileChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Loading profile data...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            SizedBox(height: 32),
            _buildPasswordSection(),
            SizedBox(height: 32),
            if (_isLoading) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
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
            'Profile Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              if (!EditProfileService.isValidUsername(value.trim())) {
                return 'Username must be 3-50 characters long';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!EditProfileService.isValidEmail(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditingPassword = !_isEditingPassword;
                    if (!_isEditingPassword) {
                      // Clear password fields when canceling
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    }
                  });
                },
                child: Text(
                  _isEditingPassword ? 'Cancel' : 'Change Password',
                  style: TextStyle(
                    color: _isEditingPassword ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (_isEditingPassword) ...[
            SizedBox(height: 16),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              isVisible: _isCurrentPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                });
              },
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              isVisible: _isNewPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isNewPasswordVisible = !_isNewPasswordVisible;
                });
              },
            ),
            SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              isVisible: _isConfirmPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                        'Update Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.withOpacity(0.5),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}