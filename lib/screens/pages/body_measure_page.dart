import 'package:aplikasi_counting_calories/service/body_measure_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/user_data.dart';

class BodyMeasurementsPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;
  final VoidCallback? onNext;
  final bool showNextButton;

  BodyMeasurementsPage({
    required this.userData, 
    required this.onChanged,
    this.onNext,
    this.showNextButton = true,
  });

  @override
  _BodyMeasurementsPageState createState() => _BodyMeasurementsPageState();
}

class _BodyMeasurementsPageState extends State<BodyMeasurementsPage> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data from UserData
    heightController.text = widget.userData.height;
    weightController.text = widget.userData.weight;
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

  // Function untuk save/update body measurements dan next
  Future<void> _saveAndNext() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Validasi input
      if (heightController.text.trim().isEmpty) {
        throw Exception('Height is required');
      }
      
      if (weightController.text.trim().isEmpty) {
        throw Exception('Current weight is required');
      }

      // Validasi numeric values
      final height = double.tryParse(heightController.text.trim());
      final weight = double.tryParse(weightController.text.trim());

      if (height == null || height <= 0) {
        throw Exception('Please enter a valid height');
      }
      
      if (weight == null || weight <= 0) {
        throw Exception('Please enter a valid current weight');
      }

      // Update data menggunakan service (tanpa goal weight)
      final result = await BodyMeasurementsService.updateBodyMeasurements(
        height: height,
        heightUnit: widget.userData.heightUnit ?? 'cm',
        weight: weight,
        weightUnit: widget.userData.weightUnit ?? 'kg',
      );

      if (result['success']) {
        // Show success message dengan custom floating snackbar
        _showFloatingSnackBar(
          context,
          result['message'] ?? 'Body measurements updated successfully',
          isSuccess: true,
        );

        // Update local UserData
        widget.userData.updateHeight(heightController.text.trim());
        widget.userData.updateWeight(weightController.text.trim());
        widget.onChanged();

        // Panggil callback next jika ada
        if (widget.onNext != null) {
          widget.onNext!();
        }

      } else {
        throw Exception(result['message'] ?? 'Failed to update body measurements');
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
              padding: EdgeInsets.all(24.0),
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Tell us about your body',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This helps us calculate your daily calorie needs.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Height Input
                  _buildInputField(
                    label: 'How tall are you?',
                    controller: heightController,
                    unit: widget.userData.heightUnit ?? 'cm',
                    onChanged: (value) {
                      widget.userData.updateHeight(value);
                      widget.onChanged();
                    },
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Weight Input
                  _buildInputField(
                    label: 'How much do you weigh?',
                    controller: weightController,
                    unit: widget.userData.weightUnit ?? 'kg',
                    onChanged: (value) {
                      widget.userData.updateWeight(value);
                      widget.onChanged();
                    },
                  ),
                  
                  SizedBox(height: 12),
                  Text(
                    'It\'s OK to estimate, you can update later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  
                  // Show BMI if available
                  if (widget.userData.bmi != null) ...[
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF363B59),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Your BMI',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${widget.userData.bmi!.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.userData.bmiCategory}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getBMIColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
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
                  onPressed: _canProceed() && !_isLoading ? _saveAndNext : null,
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

  // Check if can proceed (height dan weight ada)
  bool _canProceed() {
    return heightController.text.trim().isNotEmpty && 
           weightController.text.trim().isNotEmpty &&
           double.tryParse(heightController.text.trim()) != null &&
           double.tryParse(weightController.text.trim()) != null;
  }

  Color _getBMIColor() {
    final category = widget.userData.bmiCategory;
    switch (category) {
      case 'Normal weight':
        return Colors.green;
      case 'Underweight':
        return Colors.blue;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String unit,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isLoading,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF363B59),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Enter ${label.toLowerCase().split(' ').last}',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : () => _showUnitSelector(context, unit, label),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey[600] : Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
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
            ),
          ],
        ),
      ],
    );
  }

  void _showUnitSelector(BuildContext context, String currentUnit, String label) {
    List<String> units;
    if (label.toLowerCase().contains('tall')) {
      units = ['cm', 'ft'];
    } else {
      units = ['kg', 'lbs'];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A2E),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ...units.map((unit) => ListTile(
              title: Text(
                unit,
                style: TextStyle(color: Colors.white),
              ),
              trailing: currentUnit == unit 
                ? Icon(Icons.check, color: Color(0xFF007AFF))
                : null,
              onTap: () {
                if (label.toLowerCase().contains('tall')) {
                  widget.userData.updateHeightUnit(unit);
                } else {
                  widget.userData.updateWeightUnit(unit);
                }
                widget.onChanged();
                Navigator.pop(context);
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }
}