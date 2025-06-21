class UserData {
  int? id;
  String firstName = '';
  String mealPlanningFrequency = '';
  List<String> selectedHabits = [];
  bool? wantsWeeklyMealPlan;
  List<String> selectedGoals = [];
  int? activityLevel;
  String gender = '';
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  String weeklyGoal = '';
  
  // Additional body measurements - now consistently using double
  double height = 0.0; // in cm or feet/inches format
  double weight = 0.0; // in kg or lbs
  double goalWeight = 0.0; // target weight in kg or lbs - changed to double
  String? heightUnit = 'cm'; // 'cm' or 'ft'
  String? weightUnit = 'kg'; // 'kg' or 'lbs'
  
  // Field untuk onboarding status
  bool completedOnboarding = false;
  
  // Default constructor
  UserData({
    this.id,
    this.firstName = '',
    this.mealPlanningFrequency = '',
    List<String>? selectedHabits,
    this.wantsWeeklyMealPlan,
    List<String>? selectedGoals,
    this.activityLevel,
    this.gender = '',
    this.birthDay,
    this.birthMonth,
    this.birthYear,
    this.weeklyGoal = '',
    this.height = 0.0,
    this.weight = 0.0,
    this.goalWeight = 0.0, // changed to double
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
    this.completedOnboarding = false,
  }) : selectedHabits = selectedHabits ?? [],
       selectedGoals = selectedGoals ?? [];
  
  // BMI related - updated to work with double values
  double? get bmi {
    if (height <= 0 || weight <= 0) return null;
    
    try {
      double heightInMeters;
      double weightInKg;
      
      // Convert height to meters
      if (heightUnit == 'cm') {
        heightInMeters = height / 100;
      } else {
        // For feet, assuming decimal format (e.g., 5.8 feet)
        heightInMeters = height * 0.3048; // feet to meters
      }
      
      // Convert weight to kg
      if (weightUnit == 'kg') {
        weightInKg = weight;
      } else {
        weightInKg = weight * 0.453592; // lbs to kg
      }
      
      return weightInKg / (heightInMeters * heightInMeters);
    } catch (e) {
      return null;
    }
  }
  
  // BMI Category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal weight';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

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

  void updateActivityLevel(int level) {
    activityLevel = level;
  }

  void updateGender(String selectedGender) {
    gender = selectedGender;
  }

  void updateBirthDay(int day) {
    birthDay = day;
  }

  void updateBirthMonth(int month) {
    birthMonth = month;
  }

  void updateBirthYear(int year) {
    birthYear = year;
  }

  void updateWeeklyGoal(String goal) {
    weeklyGoal = goal;
  }
  
  // Updated methods for body measurements - now accepting double values
  void updateHeight(double newHeight) {
    height = newHeight;
  }
  
  void updateWeight(double newWeight) {
    weight = newWeight;
  }
  
  void updateGoalWeight(double newGoalWeight) {
    goalWeight = newGoalWeight;
  }
  
  void updateHeightUnit(String unit) {
    heightUnit = unit;
  }
  
  void updateWeightUnit(String unit) {
    weightUnit = unit;
  }

  // Method untuk update onboarding status
  void updateOnboardingStatus(bool completed) {
    completedOnboarding = completed;
  }

  // Helper method to get age from birth date
  int? get age {
    if (birthDay == null || birthMonth == null || birthYear == null) {
      return null;
    }
    
    final now = DateTime.now();
    final birthDate = DateTime(birthYear!, birthMonth!, birthDay!);
    
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  // Helper method to get full birth date
  DateTime? get birthDate {
    if (birthDay == null || birthMonth == null || birthYear == null) {
      return null;
    }
    return DateTime(birthYear!, birthMonth!, birthDay!);
  }
  
  // Updated validation methods for double values
  bool get hasValidHeight => height > 0;
  bool get hasValidWeight => weight > 0;
  bool get hasValidGoalWeight => goalWeight > 0;
  bool get hasValidPersonalInfo => firstName.isNotEmpty;
  bool get hasValidActivityLevel => activityLevel != null;
  
  // Check if body measurements are complete
  bool get hasCompleteBodyMeasurements => 
      hasValidHeight && hasValidWeight;

  // Check if onboarding is completed
  bool get hasCompletedOnboarding => completedOnboarding;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'mealPlanningFrequency': mealPlanningFrequency,
      'selectedHabits': selectedHabits,
      'wantsWeeklyMealPlan': wantsWeeklyMealPlan,
      'selectedGoals': selectedGoals,
      'activityLevel': activityLevel,
      'gender': gender,
      'birthDay': birthDay,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
      'weeklyGoal': weeklyGoal,
      'height': height,
      'weight': weight,
      'goalWeight': goalWeight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'completedOnboarding': completedOnboarding,
    };
  }
  
  // Factory constructor from map - updated to handle double conversion
  factory UserData.fromMap(Map<String, dynamic> map) {
    final userData = UserData();
    userData.id = map['id'];
    userData.firstName = map['firstName'] ?? '';
    userData.mealPlanningFrequency = map['mealPlanningFrequency'] ?? '';
    userData.selectedHabits = List<String>.from(map['selectedHabits'] ?? []);
    userData.wantsWeeklyMealPlan = map['wantsWeeklyMealPlan'];
    userData.selectedGoals = List<String>.from(map['selectedGoals'] ?? []);
    userData.activityLevel = map['activityLevel'];
    userData.gender = map['gender'] ?? '';
    userData.birthDay = map['birthDay'];
    userData.birthMonth = map['birthMonth'];
    userData.birthYear = map['birthYear'];
    userData.weeklyGoal = map['weeklyGoal'] ?? '';
    
    // Handle double conversion for height, weight, and goalWeight
    userData.height = (map['height'] ?? 0.0).toDouble();
    userData.weight = (map['weight'] ?? 0.0).toDouble();
    userData.goalWeight = (map['goalWeight'] ?? 0.0).toDouble();
    
    userData.heightUnit = map['heightUnit'] ?? 'cm';
    userData.weightUnit = map['weightUnit'] ?? 'kg';
    userData.completedOnboarding = map['completedOnboarding'] ?? false; 
    return userData;
  }
}