import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aplikasi_counting_calories/service/edit_profile_service.dart';
import 'dart:io';

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
  bool _hasUnsavedChanges = false;
  bool _isUploadingImage = false;

  String _originalUsername = '';
  String _originalEmail = '';
  String? _profileImageUrl;
  File? _selectedImageFile;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _setupTextControllerListeners();
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

  void _setupTextControllerListeners() {
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    // FIX: Perbaiki logika checking changes
    final hasChanges = _usernameController.text.trim() != _originalUsername ||
                      _emailController.text.trim() != _originalEmail ||
                      _selectedImageFile != null; // HAPUS kondisi ini jika foto sudah diupload
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Future<void> _loadCurrentUserData() async {
    setState(() {
      _isLoadingUserData = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load from SharedPreferences first for immediate display
      String username = prefs.getString('username') ?? 
                       prefs.getString('full_name') ?? '';
      String email = prefs.getString('email') ?? '';
      String? profileImage = prefs.getString('profileImage');

      // Update UI with cached data first
      if (mounted) {
        setState(() {
          _originalUsername = username;
          _originalEmail = email;
          _profileImageUrl = profileImage;
          _usernameController.text = username;
          _emailController.text = email;
        });
      }

      // Try to get fresh data from API
      final result = await EditProfileService.getCurrentUser();
      
      if (result.success && result.data != null) {
        final userData = result.data;
        final freshUsername = userData['username'] ?? userData['full_name'] ?? username;
        final freshEmail = userData['email'] ?? email;
        final freshProfileImage = userData['profileImage'] ?? profileImage;

        if (mounted) {
          setState(() {
            _originalUsername = freshUsername;
            _originalEmail = freshEmail;
            _profileImageUrl = freshProfileImage;
            _usernameController.text = freshUsername;
            _emailController.text = freshEmail;
          });
        }

        // Update SharedPreferences with fresh data
        if (freshProfileImage != null && freshProfileImage != profileImage) {
          await prefs.setString('profileImage', freshProfileImage);
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      if (mounted) {
        _showSnackBar('Failed to load user data', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

 Future<void> _selectImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Validate file size (5MB limit)
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (fileSize > maxSize) {
          _showSnackBar('Image size must be less than 5MB', isError: true);
          return;
        }

        setState(() {
          _selectedImageFile = file;
        });
        
        // FIX: Langsung panggil _checkForChanges setelah setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForChanges();
        });
        
        _showSnackBar('Image selected. Click Save to upload.');
      }
    } catch (e) {
      print('❌ Error selecting image: $e');
      _showSnackBar('Failed to select image', isError: true);
    }
  }

 Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Validate file size (5MB limit)
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB
        
        if (fileSize > maxSize) {
          _showSnackBar('Image size must be less than 5MB', isError: true);
          return;
        }

        setState(() {
          _selectedImageFile = file;
        });
        
        // FIX: Langsung panggil _checkForChanges setelah setState
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkForChanges();
        });
        
        _showSnackBar('Photo taken. Click Save to upload.');
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      _showSnackBar('Failed to take photo', isError: true);
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF2D2D44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Select Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blue),
                  title: Text('Gallery', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _selectImage();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.blue),
                  title: Text('Camera', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                if (_profileImageUrl != null || _selectedImageFile != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeProfileImage() async {
    final confirmed = await _showConfirmDialog(
      'Remove Profile Photo',
      'Are you sure you want to remove your profile photo?',
    );

    if (confirmed == true) {
      setState(() {
        _isUploadingImage = true;
      });

      try {
        final result = await EditProfileService.deleteProfileImage();
        
        if (result.success) {
          setState(() {
            _profileImageUrl = null;
            _selectedImageFile = null;
          });
          _showSnackBar('Profile photo removed successfully');
        } else {
          _showSnackBar(result.message ?? 'Failed to remove profile photo', isError: true);
        }
      } catch (e) {
        print('❌ Error removing profile image: $e');
        _showSnackBar('Failed to remove profile photo', isError: true);
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _refreshUserDataFromServer() async {
  try {
    final result = await EditProfileService.getCurrentUser();
    
    if (result.success && result.data != null) {
      final userData = result.data;
      final freshProfileImage = userData['profileImage'] ?? 
                               userData['profileImageUrl'] ?? 
                               userData['profile_image'];

      if (mounted && freshProfileImage != null) {
        setState(() {
          _profileImageUrl = freshProfileImage;
        });

        // Update SharedPreferences dengan data terbaru
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImage', freshProfileImage);
        await prefs.setString('profile_image', freshProfileImage);
        
        print('✅ Profile image refreshed: $freshProfileImage');
      }
    }
  } catch (e) {
    print('❌ Error refreshing user data: $e');
  }
}

  Future<void> _uploadProfileImage() async {
  if (_selectedImageFile == null) return;

  setState(() {
    _isUploadingImage = true;
  });

  try {
    final result = await EditProfileService.updateProfileImage(_selectedImageFile!);
    
    if (result.success) {
      // Clear selected file first
      setState(() {
        _selectedImageFile = null;
      });
      
      // PERBAIKAN: Refresh data dari server untuk memastikan data terbaru
      await _refreshUserDataFromServer();
      
      _showSnackBar('Profile photo updated successfully');
    } else {
      _showSnackBar(result.message ?? 'Failed to upload profile photo', isError: true);
    }
  } catch (e) {
    print('❌ Error uploading profile image: $e');
    _showSnackBar('Failed to upload profile photo', isError: true);
  } finally {
    setState(() {
      _isUploadingImage = false;
    });
  }
}

  Future<void> _saveToSharedPreferences({
    String? username,
    String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (username != null && username.isNotEmpty) {
        await prefs.setString('username', username);
        await prefs.setString('full_name', username);
        print('✅ Username saved to SharedPreferences: $username');
      }
      
      if (email != null && email.isNotEmpty) {
        await prefs.setString('email', email);
        print('✅ Email saved to SharedPreferences: $email');
      }
      
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
    bool hasAnyChanges = false;
    
    // Upload image first if selected
    if (_selectedImageFile != null) {
      await _uploadProfileImage();
      hasAnyChanges = true;
    }

    String? newUsername;
    String? newEmail;
    bool hasProfileChanges = false;

    // Check for profile data changes
    final currentUsername = _usernameController.text.trim();
    final currentEmail = _emailController.text.trim();

    if (currentUsername != _originalUsername && currentUsername.isNotEmpty) {
      newUsername = currentUsername;
      hasProfileChanges = true;
      hasAnyChanges = true;
    }

    if (currentEmail != _originalEmail && currentEmail.isNotEmpty) {
      newEmail = currentEmail;
      hasProfileChanges = true;
      hasAnyChanges = true;
    }

    if (!hasAnyChanges) {
      _showSnackBar('No changes to save');
      return;
    }

    if (hasProfileChanges) {
      // Update user data to server
      final result = await EditProfileService.updateUserData(
        username: newUsername,
        email: newEmail,
      );

      if (result.success) {
        // Update original values
        _originalUsername = newUsername ?? _originalUsername;
        _originalEmail = newEmail ?? _originalEmail;

        // Save to SharedPreferences
        await _saveToSharedPreferences(
          username: newUsername,
          email: newEmail,
        );

        _showSnackBar(result.message ?? 'Profile updated successfully');
      } else {
        _showSnackBar(result.message ?? 'Failed to update profile', isError: true);
        return;
      }
    }

    // PERBAIKAN: Refresh semua data dari server setelah update
    await _refreshUserDataFromServer();

    // Set unsaved changes ke false
    setState(() {
      _hasUnsavedChanges = false;
    });
        
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
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate inputs
    if (currentPassword.isEmpty) {
      _showSnackBar('Please enter your current password', isError: true);
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (!EditProfileService.isValidPassword(newPassword)) {
      _showSnackBar('Password must be at least 6 characters long', isError: true);
      return;
    }

    if (currentPassword == newPassword) {
      _showSnackBar('New password must be different from current password', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await EditProfileService.updatePassword(
        oldPassword: currentPassword,
        newPassword: newPassword,
      );

      if (result.success) {
        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        
        setState(() {
          _isEditingPassword = false;
        });

        // Save password update info to SharedPreferences
        await _savePasswordUpdateInfo();

        _showSnackBar(result.message ?? 'Password updated successfully');
      } else {
        _showSnackBar(result.message ?? 'Failed to update password', isError: true);
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

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardChangesDialog();
      return shouldDiscard ?? false;
    }
    return true;
  }

  Future<bool?> _showDiscardChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D44),
          title: Text(
            'Discard Changes?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D44),
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            content,
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        appBar: _buildAppBar(),
        body: _isLoadingUserData
            ? _buildLoadingWidget()
            : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          if (await _onWillPop()) {
            Navigator.of(context).pop();
          }
        },
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
        if (_hasUnsavedChanges && !_isLoading)
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
            _buildProfileImageSection(),
            SizedBox(height: 24),
            _buildProfileSection(),
            SizedBox(height: 32),
            _buildPasswordSection(),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2D2D44),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _buildProfileImageContent(),
                ),
              ),
              if (_isUploadingImage)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      border: Border.all(
                        color: Color(0xFF1A1A2E),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Tap to change profile photo',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageContent() {
    if (_selectedImageFile != null) {
      return ClipOval(
        child: Image.file(
          _selectedImageFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 60,
      color: Colors.grey[400],
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Profile Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          if (_hasUnsavedChanges) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have unsaved changes',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildPasswordSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Password',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditingPassword = !_isEditingPassword;
                    if (!_isEditingPassword) {
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    }
                  });
                },
                icon: Icon(
                  _isEditingPassword ? Icons.close : Icons.edit,
                  size: 16,
                  color: _isEditingPassword ? Colors.red : Colors.blue,
                ),
                label: Text(
                  _isEditingPassword ? 'Cancel' : 'Change',
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
                  disabledBackgroundColor: Colors.blue.withOpacity(0.5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
        errorStyle: TextStyle(color: Colors.red[300]),
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
}