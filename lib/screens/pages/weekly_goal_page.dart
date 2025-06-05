import 'package:flutter/material.dart';
import '../../models/user_data.dart';

class WeeklyGoalPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  WeeklyGoalPage({required this.userData, required this.onChanged});

  @override
  _WeeklyGoalPageState createState() => _WeeklyGoalPageState();
}

class _WeeklyGoalPageState extends State<WeeklyGoalPage> {
  final List<Map<String, dynamic>> weeklyGoals = [
    {
      'title': 'Lose 0.5 kg per week',
      'subtitle': 'Moderate weight loss',
      'description': 'Safe and sustainable approach',
      'icon': Icons.trending_down,
      'color': Color(0xFF4CAF50),
      'deficit': '-500 cal/day'
    },
    {
      'title': 'Lose 1 kg per week',
      'subtitle': 'Aggressive weight loss',
      'description': 'Requires strict discipline',
      'icon': Icons.fast_forward,
      'color': Color(0xFFFF9800),
      'deficit': '-1000 cal/day'
    },
    {
      'title': 'Maintain current weight',
      'subtitle': 'Weight maintenance',
      'description': 'Keep your current weight stable',
      'icon': Icons.balance,
      'color': Color(0xFF2196F3),
      'deficit': '0 cal/day'
    },
    {
      'title': 'Gain 0.5 kg per week',
      'subtitle': 'Gradual weight gain',
      'description': 'Build muscle and mass healthily',
      'icon': Icons.trending_up,
      'color': Color(0xFF9C27B0),
      'deficit': '+500 cal/day'
    },
    {
      'title': 'Custom goal',
      'subtitle': 'Set your own target',
      'description': 'Personalized approach',
      'icon': Icons.tune,
      'color': Color(0xFF607D8B),
      'deficit': 'Variable'
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
            'What\'s your weekly goal?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Choose a realistic goal that you can maintain long-term.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: weeklyGoals.length,
              itemBuilder: (context, index) {
                final goal = weeklyGoals[index];
                final isSelected = widget.userData.weeklyGoal == goal['title'];
                
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          widget.userData.weeklyGoal = goal['title'];
                        });
                        widget.onChanged();
                      },
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Color(0xFF007AFF) : Colors.grey[600]!,
                            width: 2,
                          ),
                          color: isSelected ? Color(0xFF007AFF).withOpacity(0.1) : Color(0xFF363B59),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: Color(0xFF007AFF).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Color(0xFF007AFF) : goal['color'],
                              ),
                              child: Icon(
                                goal['icon'],
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['title'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    goal['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[300],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    goal['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: isSelected ? Color(0xFF007AFF).withOpacity(0.2) : Colors.grey[700],
                                    ),
                                    child: Text(
                                      goal['deficit'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected ? Color(0xFF007AFF) : Colors.grey[300],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF007AFF),
                                ),
                                child: Icon(Icons.check, size: 20, color: Colors.white),
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
          
          // Info card at bottom
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remember: Sustainable changes lead to long-term success. Choose a goal you can stick to.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}