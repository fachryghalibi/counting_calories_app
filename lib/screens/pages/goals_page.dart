import 'package:flutter/material.dart';
import '../../models/user_data.dart';

class GoalsPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  GoalsPage({required this.userData, required this.onChanged});

  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final List<Map<String, dynamic>> goals = [
    {
      'title': 'Lose weight',
      'icon': Icons.trending_down,
      'description': 'Reduce body weight in a healthy way'
    },
    {
      'title': 'Gain muscle',
      'icon': Icons.fitness_center,
      'description': 'Build lean muscle mass'
    },
    {
      'title': 'Maintain weight',
      'icon': Icons.balance,
      'description': 'Keep current weight stable'
    },
    {
      'title': 'Improve energy',
      'icon': Icons.battery_charging_full,
      'description': 'Feel more energetic throughout the day'
    },
    {
      'title': 'Better digestion',
      'icon': Icons.favorite,
      'description': 'Improve digestive health'
    },
    {
      'title': 'General wellness',
      'icon': Icons.spa,
      'description': 'Overall health and wellbeing'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'What are your main health goals?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Select all that apply. This helps us personalize your experience.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = widget.userData.selectedGoals.contains(goal['title']);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            widget.userData.selectedGoals.remove(goal['title']);
                          } else {
                            widget.userData.selectedGoals.add(goal['title']);
                          }
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
                                goal['icon'],
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
                                    goal['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    goal['description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400],
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