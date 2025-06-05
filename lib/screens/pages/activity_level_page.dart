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
      'title': 'Sedentary',
      'subtitle': 'Little or no exercise',
      'description': 'Desk job, minimal physical activity',
      'icon': Icons.chair,
      'multiplier': '1.2x'
    },
    {
      'title': 'Lightly Active',
      'subtitle': 'Light exercise 1-3 days/week',
      'description': 'Some walking, light workouts',
      'icon': Icons.directions_walk,
      'multiplier': '1.375x'
    },
    {
      'title': 'Moderately Active',
      'subtitle': 'Moderate exercise 3-5 days/week',
      'description': 'Regular workouts, active lifestyle',
      'icon': Icons.directions_run,
      'multiplier': '1.55x'
    },
    {
      'title': 'Very Active',
      'subtitle': 'Hard exercise 6-7 days/week',
      'description': 'Intense training, very active job',
      'icon': Icons.fitness_center,
      'multiplier': '1.725x'
    },
    {
      'title': 'Extremely Active',
      'subtitle': 'Very hard exercise, physical job',
      'description': 'Professional athlete level activity',
      'icon': Icons.sports,
      'multiplier': '1.9x'
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
            'What\'s your activity level?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'This helps us calculate your daily caloric needs accurately.',
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
                            width: 2,
                          ),
                          color: isSelected ? Color(0xFF007AFF).withOpacity(0.1) : Color(0xFF363B59),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Color(0xFF007AFF) : Colors.grey[700],
                              ),
                              child: Icon(
                                level['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        level['title'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: isSelected ? Color(0xFF007AFF) : Colors.grey[600],
                                        ),
                                        child: Text(
                                          level['multiplier'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    level['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[300],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    level['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF007AFF),
                                ),
                                child: Icon(Icons.check, size: 16, color: Colors.white),
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