import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../models/user_data.dart';
import 'package:aplikasi_counting_calories/service/personal_info_service.dart'; // Import service yang baru dibuat

class PersonalInfoPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;
  final VoidCallback? onNext; // Tambahkan callback untuk next
  final bool showNextButton; // Flag untuk menampilkan next button

  PersonalInfoPage({
    required this.userData, 
    required this.onChanged,
    this.onNext,
    this.showNextButton = true,
  });

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Custom floating snackbar function
  void _showFloatingSnackBar(BuildContext context, String message, {required bool isSuccess}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 30,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Timer(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  void _loadUserData() {
    if (widget.userData.firstName.isNotEmpty) {
      _firstNameController.text = widget.userData.firstName;
    }
    if (widget.userData.birthDay != null) {
      _dayController.text = widget.userData.birthDay.toString();
    }
    if (widget.userData.birthMonth != null) {
      _monthController.text = widget.userData.birthMonth.toString();
    }
    if (widget.userData.birthYear != null) {
      _yearController.text = widget.userData.birthYear.toString();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  // Function untuk save/update personal info dan next
  Future<void> _saveAndNext() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi input
      if (_firstNameController.text.trim().isEmpty) {
        throw Exception('First name is required');
      }

      // Validasi tanggal lahir
      final day = widget.userData.birthDay;
      final month = widget.userData.birthMonth;
      final year = widget.userData.birthYear;

      if (day == null || month == null || year == null) {
        throw Exception('Complete birth date is required');
      }

      if (widget.userData.gender.isEmpty) {
        throw Exception('Gender selection is required');
      }

      // Format tanggal untuk backend
      final dateOfBirth = PersonalInfoService.formatDateForBackend(day, month, year);

      // Update data menggunakan service
      final result = await PersonalInfoService.updatePersonalInfo(
        username: _firstNameController.text.trim(),
        dateOfBirth: dateOfBirth,
        gender: widget.userData.gender,
      );

      if (result['success']) {
        // Show success message dengan custom floating snackbar
        _showFloatingSnackBar(
          context,
          result['message'] ?? 'Personal info updated successfully',
          isSuccess: true,
        );

        // Update local UserData
        widget.userData.updateFirstName(_firstNameController.text.trim());
        widget.onChanged();

        // Panggil callback next jika ada
        if (widget.onNext != null) {
          widget.onNext!();
        }

      } else {
        throw Exception(result['message'] ?? 'Failed to update personal info');
      }

    } catch (e) {
      // Hanya tampilkan floating SnackBar untuk error
      _showFloatingSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back to Login Button
                  GestureDetector(
                    onTap: _isLoading ? null : () async {
                      final prefs = await SharedPreferences.getInstance();
                      
                      // ✅ Hapus hanya session data, BUKAN saved credentials
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
                      
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[600]!),
                        color: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tell us a little bit about yourself',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This information helps us personalize your experience.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  // First Name
                  Text(
                    'What should we call you?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  _buildTextInput(
                    controller: _firstNameController,
                    hintText: 'Enter your first name',
                    onChanged: (value) {
                      widget.userData.updateFirstName(value);
                      widget.onChanged();
                    },
                  ),
                  SizedBox(height: 12),
                  // Gender
                  Text(
                    'Please select which sex we should use to calculate your calorie needs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(child: _buildGenderOption('Male')),
                      SizedBox(width: 12),
                      Expanded(child: _buildGenderOption('Female')),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Birth Date
                  Text(
                    'Enter your Birthday',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildNumberInput(
                              controller: _dayController,
                              hintText: 'DD',
                              maxLength: 2,
                              onChanged: (value) {
                                final day = int.tryParse(value);
                                if (day != null && day >= 1 && day <= 31) {
                                  widget.userData.updateBirthDay(day);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildNumberInput(
                              controller: _monthController,
                              hintText: 'MM',
                              maxLength: 2,
                              onChanged: (value) {
                                final month = int.tryParse(value);
                                if (month != null && month >= 1 && month <= 12) {
                                  widget.userData.updateBirthMonth(month);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Year',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildNumberInput(
                              controller: _yearController,
                              hintText: 'YYYY',
                              maxLength: 4,
                              onChanged: (value) {
                                final year = int.tryParse(value);
                                if (year != null && year >= 1900 && year <= DateTime.now().year) {
                                  widget.userData.updateBirthYear(year);
                                  widget.onChanged();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  
                  // Add some bottom padding to ensure content isn't cut off
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Next Button (integrated)
          if (widget.showNextButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50), 
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.userData.hasValidPersonalInfo && !_isLoading ? _saveAndNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    disabledBackgroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Saving...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = widget.userData.gender == gender;

    return GestureDetector(
      onTap: _isLoading ? null : () {
        if (widget.userData.gender != gender) {
          setState(() {
            widget.userData.updateGender(gender);
          });
          widget.onChanged();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF007AFF) : Colors.grey[600]!,
            width: 2,
          ),
          color: isSelected
              ? Color(0xFF007AFF).withOpacity(0.1)
              : Color(0xFF363B59),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFF007AFF) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF363B59),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        enabled: !_isLoading,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          counterText: '',
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFF363B59),
        border: Border.all(color: Colors.grey[600]!),
      ),
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
        onChanged: onChanged,
      ),
    );
  }
}