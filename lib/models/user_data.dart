class UserData {
  int? id;
  String firstName = '';
  String mealPlanningFrequency = '';
  List<String> selectedHabits = [];
  bool? wantsWeeklyMealPlan;
  List<String> selectedGoals = [];
  String? activityLevel;
  String gender = '';
  int? birthDay;
  int? birthMonth;
  int? birthYear;
  String weeklyGoal = '';
  
  // Additional body measurements
  String height = ''; // in cm or feet/inches format
  String weight = ''; // in kg or lbs
  String goalWeight = ''; // target weight in kg or lbs
  String? heightUnit = 'cm'; // 'cm' or 'ft'
  String? weightUnit = 'kg'; // 'kg' or 'lbs'
  
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
    this.height = '',
    this.weight = '',
    this.goalWeight = '',
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
  }) : selectedHabits = selectedHabits ?? [],
       selectedGoals = selectedGoals ?? [];
  
  // BMI related
  double? get bmi {
    if (height.isEmpty || weight.isEmpty) return null;
    
    try {
      double heightInMeters;
      double weightInKg;
      
      // Convert height to meters
      if (heightUnit == 'cm') {
        heightInMeters = double.parse(height) / 100;
      } else {
        // Assuming format like "5'8" or "5.8"
        if (height.contains("'")) {
          List<String> parts = height.split("'");
          double feet = double.parse(parts[0]);
          double inches = parts.length > 1 ? double.parse(parts[1].replaceAll('"', '')) : 0;
          heightInMeters = (feet * 12 + inches) * 0.0254;
        } else {
          heightInMeters = double.parse(height) * 0.3048; // feet to meters
        }
      }
      
      // Convert weight to kg
      if (weightUnit == 'kg') {
        weightInKg = double.parse(weight);
      } else {
        weightInKg = double.parse(weight) * 0.453592; // lbs to kg
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

  void updateActivityLevel(String level) {
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
  
  // New methods for body measurements
  void updateHeight(String newHeight) {
    height = newHeight;
  }
  
  void updateWeight(String newWeight) {
    weight = newWeight;
  }
  
  void updateGoalWeight(String newGoalWeight) {
    goalWeight = newGoalWeight;
  }
  
  void updateHeightUnit(String unit) {
    heightUnit = unit;
  }
  
  void updateWeightUnit(String unit) {
    weightUnit = unit;
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
  
  // Validation methods
  bool get hasValidHeight => height.isNotEmpty;
  bool get hasValidWeight => weight.isNotEmpty;
  bool get hasValidGoalWeight => goalWeight.isNotEmpty;
  bool get hasValidPersonalInfo => firstName.isNotEmpty;
  bool get hasValidActivityLevel => activityLevel != null && activityLevel!.isNotEmpty;
  
  // Check if body measurements are complete
  bool get hasCompleteBodyMeasurements => 
      hasValidHeight && hasValidWeight && hasValidGoalWeight;

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
    };
  }
  
  // Factory constructor from map
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
    userData.height = map['height'] ?? '';
    userData.weight = map['weight'] ?? '';
    userData.goalWeight = map['goalWeight'] ?? '';
    userData.heightUnit = map['heightUnit'] ?? 'cm';
    userData.weightUnit = map['weightUnit'] ?? 'kg';
    return userData;
  }
}