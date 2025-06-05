import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../../widgets/chip_option.dart';

class HealthyHabitsPage extends StatelessWidget {
  final UserData userData;
  final VoidCallback onChanged;

  const HealthyHabitsPage({
    Key? key,
    required this.userData,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recommendedHabits = [
      'Track macros',
      'Track calories',
      'Plan more meals',
    ];

    final moreHabits = [
      'Track nutrients',
      'Meal prep and cook',
      'Eat mindfully',
      'Eat a balanced diet',
      'Eat whole foods',
      'Eat more protein',
      'Eat more fiber',
      'Eat more vegetables',
      'Eat more fruit',
      'Drink more water',
      'Prioritize sleep',
      'Move more',
      'Workout more',
      'Something else',
    ];

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40),
          Text(
            'Which healthy habits are most important to you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for you',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendedHabits.map((habit) {
                      return ChipOption(
                        label: habit,
                        isSelected: userData.selectedHabits.contains(habit),
                        onTap: () {
                          userData.toggleHealthyHabit(habit);
                          onChanged();
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'More healthy habits',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moreHabits.map((habit) {
                      return ChipOption(
                        label: habit,
                        isSelected: userData.selectedHabits.contains(habit),
                        onTap: () {
                          userData.toggleHealthyHabit(habit);
                          onChanged();
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  ChipOption(
                    label: "I'm not sure",
                    isSelected: userData.selectedHabits.contains("I'm not sure"),
                    onTap: () {
                      userData.toggleHealthyHabit("I'm not sure");
                      onChanged();
                    },
                    isSpecial: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}