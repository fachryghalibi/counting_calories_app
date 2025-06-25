import 'package:aplikasi_counting_calories/service/body_measure_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditBodyMeasurePage extends StatefulWidget {
  const EditBodyMeasurePage({Key? key}) : super(key: key);

  @override
  _EditBodyMeasurePageState createState() => _EditBodyMeasurePageState();
}

class _EditBodyMeasurePageState extends State<EditBodyMeasurePage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  
  // Current values for BMI calculation
  double _currentHeight = 0.0;
  double _currentWeight = 0.0;
  double _currentBMI = 0.0;
  String _bmiCategory = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      final prefs = await SharedPreferences.getInstance();
      
      // Load from SharedPreferences first
      final height = prefs.getDouble('height') ?? 0.0;
      final weight = prefs.getDouble('weight') ?? 0.0;

      // Try to get fresh data from API
      final result = await BodyMeasurementsService.getCurrentUserData();
      
      if (result['success'] && result['data'] != null) {
        final userData = result['data'];
        _currentHeight = (userData['height'] ?? height).toDouble();
        _currentWeight = (userData['weight'] ?? weight).toDouble();
      } else {
        // Fallback to local data
        _currentHeight = height;
        _currentWeight = weight;
      }

      // Update controllers
      _heightController.text = _currentHeight > 0 ? _currentHeight.toStringAsFixed(1) : '';
      _weightController.text = _currentWeight > 0 ? _currentWeight.toStringAsFixed(1) : '';

      // Calculate BMI
      _calculateBMI();

    } catch (e) {
      print('❌ Error loading current data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading current data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _calculateBMI() {
    if (_currentHeight > 0 && _currentWeight > 0) {
      _currentBMI = BodyMeasurementsService.calculateBMI(_currentHeight, _currentWeight);
      _bmiCategory = BodyMeasurementsService.getBMICategory(_currentBMI);
    } else {
      _currentBMI = 0.0;
      _bmiCategory = '';
    }
  }

  Future<void> _saveBodyMeasurements() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);

      final result = await BodyMeasurementsService.updateBodyMeasurements(
        height: height,
        heightUnit: 'cm',
        weight: weight,
        weightUnit: 'kg',
      );

      if (result['success']) {
        // Save unit preferences to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('heightUnit', 'cm');
        await prefs.setString('weightUnit', 'kg');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Body measurements updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Return true to indicate successful update
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update body measurements'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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

  void _onHeightChanged(String value) {
    if (value.isNotEmpty) {
      try {
        final height = double.parse(value);
        
        setState(() {
          _currentHeight = height;
          _calculateBMI();
        });
      } catch (e) {
        // Invalid input, ignore
      }
    }
  }

  void _onWeightChanged(String value) {
    if (value.isNotEmpty) {
      try {
        final weight = double.parse(value);
        
        setState(() {
          _currentWeight = weight;
          _calculateBMI();
        });
      } catch (e) {
        // Invalid input, ignore
      }
    }
  }

  Color _getBMIColor() {
    if (_currentBMI == 0.0) return Colors.grey;
    
    switch (_bmiCategory) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal weight':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Body Measurements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BMI Card
                    if (_currentBMI > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(0xFF2D2D44),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _getBMIColor(), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Current BMI',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _currentBMI.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getBMIColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _bmiCategory,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],

                    // Height Section
                    Text(
                      'Height',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF2D2D44),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Colors.white),
                        onChanged: _onHeightChanged,
                        decoration: InputDecoration(
                          hintText: 'Enter your height',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixText: 'cm',
                          suffixStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Weight Section
                    Text(
                      'Weight',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF2D2D44),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: Colors.white),
                        onChanged: _onWeightChanged,
                        decoration: InputDecoration(
                          hintText: 'Enter your weight',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixText: 'kg',
                          suffixStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: 32),

                    // Save Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveBodyMeasurements,
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
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}