import 'package:flutter/material.dart';
import '../../models/user_data.dart';

class MealPlanningPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  MealPlanningPage({required this.userData, required this.onChanged});

  @override
  _MealPlanningPageState createState() => _MealPlanningPageState();
}

class _MealPlanningPageState extends State<MealPlanningPage> {
  final List<String> frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Occasionally',
    'Never',
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
            'How often do you plan your meals?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'This helps us understand your meal preparation habits',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: frequencies.length,
              itemBuilder: (context, index) {
                final frequency = frequencies[index];
                final isSelected = widget.userData.mealPlanningFrequency == frequency;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          widget.userData.mealPlanningFrequency = frequency;
                        });
                        widget.onChanged();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Color(0xFF007AFF) : Color(0xFF363B59),
                            width: 2,
                          ),
                          color: isSelected ? Color(0xFF007AFF).withOpacity(0.1) : Color(0xFF363B59),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Color(0xFF007AFF) : Colors.grey[600]!,
                                  width: 2,
                                ),
                                color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, size: 12, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 16),
                            Text(
                              frequency,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
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