import 'package:flutter/material.dart';
import '../../models/user_data.dart';

class ActivityLevelPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  ActivityLevelPage({required this.userData, required this.onChanged});

  @override
  _ActivityLevelPageState createState() => _ActivityLevelPageState();
}

class _ActivityLevelPageState extends State<ActivityLevelPage> {
  final List<Map<String, dynamic>> activityLevels = [
    {
      'title': 'Not Very Active',
      'subtitle': 'Spend most of the day sitting (e.g., bank teller, desk job)',
      'description': '',
      'icon': Icons.chair,
      'multiplier': ''
    },
    {
      'title': 'Lightly Active',
      'subtitle': 'Spend a good part of the day on your feet (e.g., teacher, salesperson)',
      'description': '',
      'icon': Icons.directions_walk,
      'multiplier': ''
    },
    {
      'title': 'Active',
      'subtitle': 'Spend a good part of the day doing some physical activity (e.g., food server, carrier)',
      'description': '',
      'icon': Icons.directions_run,
      'multiplier': ''
    },
    {
      'title': 'Very Active',
      'subtitle': 'Spend a good part of the day doing some physical activity (e.g., food server, carrier)',
      'description': '',
      'icon': Icons.fitness_center,
      'multiplier': ''
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
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
          Expanded(
            child: ListView.builder(
              itemCount: activityLevels.length,
              itemBuilder: (context, index) {
                final level = activityLevels[index];
                final isSelected = widget.userData.activityLevel == level['title'];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          widget.userData.updateActivityLevel(level['title']);
                        });
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
          ),
        ],
      ),
    );
  }
}