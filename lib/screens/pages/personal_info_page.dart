import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_data.dart';
import 'package:country_picker/country_picker.dart';

class PersonalInfoPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  PersonalInfoPage({required this.userData, required this.onChanged});

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

@override
void initState() {
  super.initState();
  if (widget.userData.age != null && widget.userData.age! > 0) {
    _ageController.text = widget.userData.age.toString();
  }
  if (widget.userData.location.isNotEmpty) {
    _locationController.text = widget.userData.location;
  }
}


  @override
  void dispose() {
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'This information helps us personalize your experience.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 40),

              // Gender
              Text(
                'Gender',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildGenderOption('Male', Icons.male)),
                  SizedBox(width: 12),
                  Expanded(child: _buildGenderOption('Female', Icons.female)),
                  SizedBox(width: 12),
                ],
              ),

              SizedBox(height: 32),

              // Age
              Text(
                'Age',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              _buildNumberInput(
                controller: _ageController,
                hintText: 'Enter your age',
                onChanged: (value) {
                  final age = int.tryParse(value);
                  if (age != null) {
                    widget.userData.updateAge(age);
                    widget.onChanged();
                  }
                },
              ),

              SizedBox(height: 24),

              // Location
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode:
                        true, 
                    onSelect: (Country country) {
                      setState(() {
                        _locationController.text = country.name;
                      });
                      widget.userData.updateLocation(country.name);
                      widget.onChanged();
                    },
                  );
                },
                child: AbsorbPointer(
                  child: _buildTextInput(
                    controller: _locationController,
                    hintText: 'Select your country',
                    onChanged: (value) {},
                  ),
                ),
              ),

              SizedBox(
                  height:
                      80), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = widget.userData.gender == gender;

    return GestureDetector(
      onTap: () {
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Color(0xFF007AFF) : Colors.grey[400],
            ),
            SizedBox(height: 8),
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
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        style: TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }
}