// pages/body_measure_page.dart - Updated for double values
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_counting_calories/models/user_data.dart';

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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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

          // Next Button
          if (widget.showNextButton)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.userData.hasCompleteBodyMeasurements 
                    ? widget.onNext 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.userData.hasCompleteBodyMeasurements 
                      ? Colors.white 
                      : Colors.grey[600],
                  foregroundColor: widget.userData.hasCompleteBodyMeasurements 
                      ? Color(0xFF1A1A2E) 
                      : Colors.grey[400],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
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
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
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
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
                onChanged: onChanged,
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: onUnitToggle,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
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