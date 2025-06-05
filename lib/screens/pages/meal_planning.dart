import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../../widgets/radio_option.dart';

class MealPlanningPage extends StatelessWidget {
  final UserData userData;
  final VoidCallback onChanged;

  const MealPlanningPage({
    Key? key,
    required this.userData,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final options = [
      'Never',
      'Rarely',
      'Occasionally',
      'Frequently',
      'Always',
    ];

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'How often do you plan your meals in advance?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                return RadioOption(
                  title: options[index],
                  isSelected: userData.mealPlanningFrequency == options[index],
                  onTap: () {
                    userData.updateMealPlanningFrequency(options[index]);
                    onChanged();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}