import 'package:flutter/material.dart';
import '../../models/user_data.dart';

class WeeklyMealPlanPage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  WeeklyMealPlanPage({required this.userData, required this.onChanged});

  @override
  _WeeklyMealPlanPageState createState() => _WeeklyMealPlanPageState();
}

class _WeeklyMealPlanPageState extends State<WeeklyMealPlanPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'Would you like weekly meal plan suggestions?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'We can create personalized meal plans to help you stay on track with your goals.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 60),
          
          // Yes Option
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    widget.userData.wantsWeeklyMealPlan = true;
                  });
                  widget.onChanged();
                },
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.userData.wantsWeeklyMealPlan == true 
                          ? Color(0xFF007AFF) 
                          : Colors.grey[600]!,
                      width: 2,
                    ),
                    color: widget.userData.wantsWeeklyMealPlan == true 
                        ? Color(0xFF007AFF).withOpacity(0.1) 
                        : Color(0xFF363B59),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.userData.wantsWeeklyMealPlan == true 
                              ? Color(0xFF007AFF) 
                              : Colors.grey[700],
                        ),
                        child: Icon(
                          Icons.calendar_today,
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
                              'Yes, I want meal plans',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Get personalized weekly meal suggestions based on your preferences and goals',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.userData.wantsWeeklyMealPlan == true)
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
          ),

          // No Option
          Container(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    widget.userData.wantsWeeklyMealPlan = false;
                  });
                  widget.onChanged();
                },
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.userData.wantsWeeklyMealPlan == false 
                          ? Color(0xFF007AFF) 
                          : Colors.grey[600]!,
                      width: 2,
                    ),
                    color: widget.userData.wantsWeeklyMealPlan == false 
                        ? Color(0xFF007AFF).withOpacity(0.1) 
                        : Color(0xFF363B59),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.userData.wantsWeeklyMealPlan == false 
                              ? Color(0xFF007AFF) 
                              : Colors.grey[700],
                        ),
                        child: Icon(
                          Icons.close,
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
                              'No, I\'ll plan myself',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'I prefer to create my own meal plans without suggestions',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.userData.wantsWeeklyMealPlan == false)
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
          ),

          Spacer(),
        ],
      ),
    );
  }
}