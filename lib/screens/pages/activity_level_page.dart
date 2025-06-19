import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/user_data.dart';

class ActivityLevelPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;
  final VoidCallback? onNext; // This is void Function()? - cannot be awaited
  final bool showNextButton;

  ActivityLevelPage({
    required this.userData,
    required this.onChanged,
    this.onNext,
    this.showNextButton = true,
  });

  @override
  _ActivityLevelPageState createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  bool _isLoading = false;

  // ✅ FIXED: Update activity levels dengan level sebagai int
  final List<Map<String, dynamic>> activityLevels = [
    {
      'title': 'Not Very Active',
      'subtitle': 'Spend most of the day sitting (e.g., bank teller, desk job)',
      'level': 1, // ✅ int value untuk database
      'icon': Icons.chair,
    },
    {
      'title': 'Lightly Active',
      'subtitle': 'Spend a good part of the day on your feet (e.g., teacher, salesperson)',
      'level': 2, // ✅ int value untuk database
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Active',
      'subtitle': 'Spend a good part of the day doing some physical activity (e.g., food server, carrier)',
      'level': 3, // ✅ int value untuk database
      'icon': Icons.directions_run,
    },
    {
      'title': 'Very Active',
      'subtitle': 'Spend most of the day doing heavy physical activity (e.g., construction worker, athlete)',
      'level': 4, // ✅ int value untuk database
      'icon': Icons.fitness_center,
    },
  ];

  @override
  void initState() {
    super.initState();
    print('🔄 ActivityLevelPage initialized');
    print('📊 Current userData.activityLevel: ${widget.userData.activityLevel}');
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

  // ✅ FIXED: Handle next dengan validasi yang benar - REMOVED AWAIT
  Future<void> _handleNext() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ FIXED: Validasi activity level sebagai int
      if (widget.userData.activityLevel == null) {
        throw Exception('Please select an activity level');
      }

      final activityLevel = widget.userData.activityLevel!;
      if (activityLevel < 1 || activityLevel > 4) {
        throw Exception('Invalid activity level selected');
      }

      print('🔄 Activity level selected: $activityLevel');
      print('📊 Activity level validation passed');

      // ✅ FIXED: Panggil callback onNext tanpa await (karena void function)
      if (widget.onNext != null) {
        print('🔄 Calling onNext callback...');
        widget.onNext!(); // REMOVED await - VoidCallback cannot be awaited
      } else {
        print('⚠️ No onNext callback provided');
      }

    } catch (e) {
      print('❌ Error in activity level page: $e');
      _showFloatingSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ✅ FIXED: Helper method untuk mendapatkan activity level yang dipilih
  Map<String, dynamic>? get selectedActivityLevel {
    if (widget.userData.activityLevel == null) return null;
    
    try {
      return activityLevels.firstWhere(
        (level) => level['level'] == widget.userData.activityLevel,
      );
    } catch (e) {
      print('⚠️ Selected activity level not found: ${widget.userData.activityLevel}');
      return null;
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
                  SizedBox(height: 40),
                  Text(
                    'What\'s your baseline\nactivity level?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Choose what describes you best :',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 40),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: activityLevels.length,
                    itemBuilder: (context, index) {
                      final level = activityLevels[index];
                      // ✅ FIXED: Perbandingan berdasarkan level (int) bukan title (String)
                      final isSelected = widget.userData.activityLevel == level['level'];
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _isLoading ? null : () {
                              final selectedLevel = level['level'] as int;
                              print('🔄 Selected activity level: ${level['title']} (level: $selectedLevel)');
                              
                              // ✅ FIXED: Update dengan int level, bukan String title
                              setState(() {
                                widget.userData.updateActivityLevel(selectedLevel);
                              });
                              
                              print('📊 Updated userData.activityLevel: ${widget.userData.activityLevel}');
                              widget.onChanged();
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF007AFF) : Colors.grey[600]!,
                                  width: 1,
                                ),
                                color: isSelected ? Color(0xFF007AFF).withOpacity(0.1) : Color(0xFF363B59),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          level['title'],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          level['subtitle'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Color(0xFF007AFF) : Colors.grey[600]!,
                                        width: 2,
                                      ),
                                      color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
                                    ),
                                    child: isSelected 
                                      ? Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // ✅ FIXED: Next Button dengan validasi yang benar
          if (widget.showNextButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 50), 
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.userData.hasValidActivityLevel && !_isLoading ? _handleNext : null,
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
                        'Get Started',
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
}