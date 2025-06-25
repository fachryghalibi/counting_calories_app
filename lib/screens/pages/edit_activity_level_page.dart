import 'package:aplikasi_counting_calories/service/activity_level_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditActivityLevelPage extends StatefulWidget {
  const EditActivityLevelPage({Key? key}) : super(key: key);

  @override
  _EditActivityLevelPageState createState() => _EditActivityLevelPageState();
}

class _EditActivityLevelPageState extends State<EditActivityLevelPage> {
  bool _isLoading = false;
  bool _isSaving = false;
  int _selectedActivityLevel = 1;
  int _originalActivityLevel = 1;
  
  final List<Map<String, dynamic>> _activityLevels = [
    {
      'level': 1,
      'title': 'Not Very Active',
      'description': 'Little to no exercise, desk job',
      'multiplier': '1.2x BMR',
      'icon': Icons.chair_outlined,
    },
    {
      'level': 2,
      'title': 'Lightly Active',
      'description': 'Light exercise 1-3 days/week',
      'multiplier': '1.375x BMR',
      'icon': Icons.directions_walk_outlined,
    },
    {
      'level': 3,
      'title': 'Active',
      'description': 'Moderate exercise 3-5 days/week',
      'multiplier': '1.55x BMR',
      'icon': Icons.fitness_center_outlined,
    },
    {
      'level': 4,
      'title': 'Very Active',
      'description': 'Heavy exercise 6-7 days/week',
      'multiplier': '1.725x BMR',
      'icon': Icons.directions_run_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentActivityLevel();
    // Debug activity level on page load
    ActivityLevelService.debugActivityLevel();
  }

  Future<void> _loadCurrentActivityLevel() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Loading current activity level...');
      
      // Try to get from service first
      final currentLevel = await ActivityLevelService.getCurrentActivityLevel();
      
      if (currentLevel != null && currentLevel >= 1 && currentLevel <= 4) {
        setState(() {
          _selectedActivityLevel = currentLevel;
          _originalActivityLevel = currentLevel;
        });
        print('✅ Current activity level loaded: $currentLevel');
      } else {
        // Fallback to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final storedLevel = prefs.getInt('activityLevel') ?? 1;
        setState(() {
          _selectedActivityLevel = storedLevel;
          _originalActivityLevel = storedLevel;
        });
        print('✅ Fallback activity level loaded: $storedLevel');
      }
      
    } catch (e) {
      print('❌ Error loading activity level: $e');
      // Default to level 1 if error
      setState(() {
        _selectedActivityLevel = 1;
        _originalActivityLevel = 1;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading activity level: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveActivityLevel() async {
    if (_selectedActivityLevel == _originalActivityLevel) {
      // No changes made, just go back
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      print('🔄 Saving activity level: $_selectedActivityLevel');
      
      final result = await ActivityLevelService.updateActivityLevel(
        activityLevel: _selectedActivityLevel,
      );
      
      print('🔄 Save result: $result');

      if (result['success'] == true) {
        print('✅ Activity level saved successfully');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Activity level updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Return true to indicate successful update
        Navigator.of(context).pop(true);
        
      } else {
        print('❌ Failed to save activity level: ${result['message']}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update activity level'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
    } catch (e) {
      print('❌ Exception saving activity level: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving activity level: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDiscardChangesDialog() {
    if (_selectedActivityLevel == _originalActivityLevel) {
      // No changes made, just go back
      Navigator.of(context).pop(false);
      return;
    }

    showDialog(
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
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(false); // Close page
              },
              child: Text(
                'Discard',
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
    return WillPopScope(
      onWillPop: () async {
        _showDiscardChangesDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _showDiscardChangesDialog,
          ),
          title: Text(
            'Edit Activity Level',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCard(),
                          SizedBox(height: 24),
                          _buildActivityLevelOptions(),
                          SizedBox(height: 24),
                          _buildSelectedActivityInfo(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Activity Level',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Your activity level helps calculate your daily calorie needs. Choose the option that best describes your typical weekly activity.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Activity Level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        ..._activityLevels.map((activity) => _buildActivityOption(activity)),
      ],
    );
  }

  Widget _buildActivityOption(Map<String, dynamic> activity) {
    final bool isSelected = _selectedActivityLevel == activity['level'];
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedActivityLevel = activity['level'];
          });
        },
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity['icon'],
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      activity['description'],
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      activity['multiplier'],
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.blue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedActivityInfo() {
    final selectedActivity = _activityLevels.firstWhere(
      (activity) => activity['level'] == _selectedActivityLevel,
    );
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Selected Activity Level',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            selectedActivity['title'],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            selectedActivity['description'],
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Multiplier: ${selectedActivity['multiplier']}',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final bool hasChanges = _selectedActivityLevel != _originalActivityLevel;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isSaving || !hasChanges) ? null : _saveActivityLevel,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasChanges ? Colors.blue : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    hasChanges ? 'Save Changes' : 'No Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}