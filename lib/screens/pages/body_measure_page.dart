// pages/body_measure_page.dart - Updated with consistent colors and snackbar
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_counting_calories/models/user_data.dart';
import 'dart:async';

class BodyMeasurementsPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;
  final VoidCallback onNext;
  final bool showNextButton;

  const BodyMeasurementsPage({
    Key? key,
    required this.userData,
    required this.onChanged,
    required this.onNext,
    this.showNextButton = true,
  }) : super(key: key);

  @override
  _BodyMeasurementsPageState createState() => _BodyMeasurementsPageState();
}

class _BodyMeasurementsPageState extends State<BodyMeasurementsPage> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _goalWeightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with double values
    _heightController = TextEditingController(
      text: widget.userData.height > 0 ? widget.userData.height.toString() : ''
    );
    _weightController = TextEditingController(
      text: widget.userData.weight > 0 ? widget.userData.weight.toString() : ''
    );
    _goalWeightController = TextEditingController(
      text: widget.userData.goalWeight > 0 ? widget.userData.goalWeight.toString() : ''
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  // Custom floating snackbar function (same as personal info)
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

  void _updateHeight(String value) {
    // Parse as double and handle errors
    final doubleValue = double.tryParse(value) ?? 0.0;
    widget.userData.updateHeight(doubleValue);
    widget.onChanged();
  }

  void _updateWeight(String value) {
    // Parse as double and handle errors
    final doubleValue = double.tryParse(value) ?? 0.0;
    widget.userData.updateWeight(doubleValue);
    widget.onChanged();
  }

  void _updateGoalWeight(String value) {
    // Parse as double and handle errors
    final doubleValue = double.tryParse(value) ?? 0.0;
    widget.userData.updateGoalWeight(doubleValue);
    widget.onChanged();
  }

  void _toggleHeightUnit() {
    setState(() {
      if (widget.userData.heightUnit == 'cm') {
        // Convert cm to ft
        if (widget.userData.height > 0) {
          final newHeight = widget.userData.height / 30.48;
          widget.userData.updateHeight(newHeight);
          widget.userData.updateHeightUnit('ft');
          _heightController.text = newHeight.toStringAsFixed(1);
        } else {
          widget.userData.updateHeightUnit('ft');
        }
      } else {
        // Convert ft to cm
        if (widget.userData.height > 0) {
          final newHeight = widget.userData.height * 30.48;
          widget.userData.updateHeight(newHeight);
          widget.userData.updateHeightUnit('cm');
          _heightController.text = newHeight.toStringAsFixed(0);
        } else {
          widget.userData.updateHeightUnit('cm');
        }
      }
      widget.onChanged();
    });
  }

  void _toggleWeightUnit() {
    setState(() {
      if (widget.userData.weightUnit == 'kg') {
        // Convert kg to lbs
        if (widget.userData.weight > 0) {
          final newWeight = widget.userData.weight / 0.453592;
          widget.userData.updateWeight(newWeight);
          _weightController.text = newWeight.toStringAsFixed(1);
        }
        
        if (widget.userData.goalWeight > 0) {
          final newGoalWeight = widget.userData.goalWeight / 0.453592;
          widget.userData.updateGoalWeight(newGoalWeight);
          _goalWeightController.text = newGoalWeight.toStringAsFixed(1);
        }
        
        widget.userData.updateWeightUnit('lbs');
      } else {
        // Convert lbs to kg
        if (widget.userData.weight > 0) {
          final newWeight = widget.userData.weight * 0.453592;
          widget.userData.updateWeight(newWeight);
          _weightController.text = newWeight.toStringAsFixed(1);
        }
        
        if (widget.userData.goalWeight > 0) {
          final newGoalWeight = widget.userData.goalWeight * 0.453592;
          widget.userData.updateGoalWeight(newGoalWeight);
          _goalWeightController.text = newGoalWeight.toStringAsFixed(1);
        }
        
        widget.userData.updateWeightUnit('kg');
      }
      widget.onChanged();
    });
  }

  // Function to simulate saving body measurements
  Future<void> _saveAndNext() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validate inputs
      if (!widget.userData.hasCompleteBodyMeasurements) {
        throw Exception('Please complete all body measurements');
      }

      // Simulate API call delay
      await Future.delayed(Duration(milliseconds: 1000));

      // Show success message
      _showFloatingSnackBar(
        context,
        'Body measurements saved successfully!',
        isSuccess: true,
      );

      // Delay a bit for user to see the snackbar
      await Future.delayed(Duration(milliseconds: 500));

      // Call next callback
      widget.onNext();

    } catch (e) {
      // Show error message
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s set up your body measurements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This helps us calculate your daily calorie needs',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 32),

          // Height Input
          _buildMeasurementInput(
            label: 'Height',
            controller: _heightController,
            unit: widget.userData.heightUnit ?? 'cm',
            onUnitToggle: _toggleHeightUnit,
            onChanged: _updateHeight,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          SizedBox(height: 24),

          // Current Weight Input
          _buildMeasurementInput(
            label: 'Current Weight',
            controller: _weightController,
            unit: widget.userData.weightUnit ?? 'kg',
            onUnitToggle: _toggleWeightUnit,
            onChanged: _updateWeight,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          SizedBox(height: 24),

          // Goal Weight Input
          _buildMeasurementInput(
            label: 'Goal Weight',
            controller: _goalWeightController,
            unit: widget.userData.weightUnit ?? 'kg',
            onUnitToggle: _toggleWeightUnit,
            onChanged: _updateGoalWeight,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),

          // BMI Display
          if (widget.userData.hasCompleteBodyMeasurements && widget.userData.bmi != null) ...[
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF363B59), // Match personal info color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!), // Match personal info border
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your BMI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.userData.bmi!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.userData.bmiCategory ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: _getBMIColor(widget.userData.bmi!),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          Spacer(),

          // Next Button - Updated to match personal info style
          if (widget.showNextButton)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.userData.hasCompleteBodyMeasurements && !_isLoading
                    ? _saveAndNext 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // Match personal info button color
                  disabledBackgroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26), // Match personal info border radius
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
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput({
    required String label,
    required TextEditingController controller,
    required String unit,
    required VoidCallback onUnitToggle,
    required Function(String) onChanged,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xFF363B59), // Match personal info background color
                  border: Border.all(color: Colors.grey[600]!), // Match personal info border
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  enabled: !_isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none, // Remove default border
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17), // Match personal info padding
                  ),
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : onUnitToggle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17), // Match input field height
                decoration: BoxDecoration(
                  color: Color(0xFF363B59), // Match personal info background color
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!), // Match personal info border
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) {
      return Colors.blue[300]!;
    } else if (bmi >= 18.5 && bmi < 25) {
      return Colors.green[300]!;
    } else if (bmi >= 25 && bmi < 30) {
      return Colors.orange[300]!;
    } else {
      return Colors.red[300]!;
    }
  }
}