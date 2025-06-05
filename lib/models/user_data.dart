class UserData {
  String firstName = '';
  String mealPlanningFrequency = '';
  List<String> selectedHabits = [];
  bool? wantsWeeklyMealPlan;
  List<String> selectedGoals = [];
  String? activityLevel;
  String gender = '';
  int? age;
  String location = ' ';
  String weeklyGoal = '';

  // Methods to update data
  void updateFirstName(String name) {
    firstName = name;
  }

  void updateMealPlanningFrequency(String frequency) {
    mealPlanningFrequency = frequency;
  }

  void toggleHealthyHabit(String habit) {
    if (selectedHabits.contains(habit)) {
      selectedHabits.remove(habit);
    } else {
      selectedHabits.add(habit);
    }
  }

  void updateWeeklyMealPlan(bool wants) {
    wantsWeeklyMealPlan = wants;
  }

  void toggleGoal(String goal) {
    if (selectedGoals.contains(goal)) {
      selectedGoals.remove(goal);
    } else {
      if (selectedGoals.length < 3) {
        selectedGoals.add(goal);
      }
    }
  }

  void updateActivityLevel(String level) {
    activityLevel = level;
  }

  void updateGender(String selectedGender) {
    gender = selectedGender;
  }

  void updateAge(int selectedAge) {
    age = selectedAge;
  }

  void updateLocation(String selectedLocation) {
    location = selectedLocation;
  }

  void updateWeeklyGoal(String goal) {
    weeklyGoal = goal;
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'mealPlanningFrequency': mealPlanningFrequency,
      'selectedHabits': selectedHabits,
      'wantsWeeklyMealPlan': wantsWeeklyMealPlan,
      'selectedGoals': selectedGoals,
      'activityLevel': activityLevel,
      'gender': gender,
      'age': age,
      'location': location,
      'weeklyGoal': weeklyGoal,
    };
  }

  
}