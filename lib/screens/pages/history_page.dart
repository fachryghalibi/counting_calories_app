import 'package:aplikasi_counting_calories/service/history_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime selectedDate = DateTime.now();
  List<DateTime> weekDates = [];
  Map<String, double> weeklyCalories = {};
  List<MealGroup> todayMeals = [];
  double todayTotalCalories = 473;
  double targetCalories = 2200;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateWeekDates();
    _loadInitialData();
  }

  void _generateWeekDates() {
    // Generate 7 days dengan hari ini di tengah (index 3)
    DateTime now = DateTime.now();
    
    weekDates = List.generate(7, (index) => 
      now.add(Duration(days: index - 3))
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load weekly calories
      await _loadWeeklyCalorieData();
      // Load today's detail
      await _loadDayDetailData(selectedDate);
    } catch (e) {
      _showErrorSnackbar('Failed to load data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadWeeklyCalorieData() async {
    try {
      final response = await HistoryService.getDailyCalorieLog();
      
      // Initialize weekly data dengan tanggal sebagai key
      Map<String, double> weeklyData = {};
      
      // Initialize all week dates to 0
      for (DateTime date in weekDates) {
        String dateKey = DateFormat('yyyy-MM-dd').format(date);
        weeklyData[dateKey] = 0;
      }
      
      // Check if response is valid and contains data
      if (response.isNotEmpty) {
        final calorieLog = DailyCalorieLog.fromJson(response);
        
        // Map data dari API berdasarkan tanggal
        for (var dayData in calorieLog.days) {
          try {
            String dateKey = dayData.date;
            
            // Jika tanggal ada dalam minggu ini
            if (weeklyData.containsKey(dateKey)) {
              // Jika totalCalories tidak ada dari API, ambil dari detail
              if (dayData.totalCalories != null) {
                weeklyData[dateKey] = dayData.totalCalories!;
              } else {
                // Ambil dari detail scans
                try {
                  final detailResponse = await HistoryService.getDayDetailScans(dayData.date);
                  final dayDetail = DayDetailScans.fromJson(detailResponse);
                  weeklyData[dateKey] = dayDetail.totalCalories;
                } catch (e) {
                  print('Error loading detail for ${dayData.date}: $e');
                  weeklyData[dateKey] = 0;
                }
              }
            }
          } catch (e) {
            print('Error parsing date ${dayData.date}: $e');
            continue;
          }
        }
      } else {
        print('Invalid response format: $response');
      }
      
      setState(() {
        weeklyCalories = weeklyData;
      });
    } catch (e) {
      print('Error in _loadWeeklyCalorieData: $e');
      // Fallback ke mock data jika API error
      Map<String, double> fallbackData = {};
      for (DateTime date in weekDates) {
        String dateKey = DateFormat('yyyy-MM-dd').format(date);
        fallbackData[dateKey] = date.day == DateTime.now().day ? 473 : 0;
      }
      
      setState(() {
        weeklyCalories = fallbackData;
      });
      throw Exception('Error loading weekly data: $e');
    }
  }

  Future<void> _loadDayDetailData(DateTime date) async {
    try {
      String dateString = DateFormat('yyyy-MM-dd').format(date);
      final response = await HistoryService.getDayDetailScans(dateString);
      final dayDetail = DayDetailScans.fromJson(response);
      
      setState(() {
        todayMeals = dayDetail.meals;
        todayTotalCalories = dayDetail.totalCalories;
      });
    } catch (e) {
      // Fallback ke mock data jika API error
      setState(() {
        todayMeals = [
          MealGroup(
            mealType: 'Breakfast',
            time: '7:30 AM',
            totalCalories: 343,
            foods: [
              FoodItem(name: 'Nasi Goreng', calories: 343, icon: '🍚'),
              FoodItem(name: 'Rice', calories: 138),
              FoodItem(name: 'Eggs', calories: 140),
            ],
          ),
          MealGroup(
            mealType: 'Lunch',
            time: '7:30 AM',
            totalCalories: 130,
            foods: [
              FoodItem(name: 'Manggo Juice', calories: 130, icon: '🥤'),
            ],
          ),
        ];
        todayTotalCalories = weeklyCalories[DateFormat('yyyy-MM-dd').format(date)] ?? 0;
      });
      throw Exception('Error loading day detail: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onDateSelected(DateTime date) async {
    if (date != selectedDate) {
      setState(() {
        selectedDate = date;
        isLoading = true;
      });
      
      try {
        await _loadDayDetailData(date);
      } catch (e) {
        _showErrorSnackbar('Failed to load data for ${DateFormat('MMM dd').format(date)}');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.grey),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                  // Update week dates dengan tanggal yang dipilih di tengah
                  weekDates = List.generate(7, (index) => 
                    picked.add(Duration(days: index - 3))
                  );
                });
                await _loadWeeklyCalorieData();
                await _loadDayDetailData(picked);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWeeklyCalendar(),
            const SizedBox(height: 20),
            _buildCaloriesSummary(),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildTodayMeals(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar() {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        DateTime date = weekDates[index];
        bool isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                         DateFormat('yyyy-MM-dd').format(selectedDate);
        bool isToday = DateFormat('yyyy-MM-dd').format(date) == 
                      DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        String dateKey = DateFormat('yyyy-MM-dd').format(date);
        double calories = weeklyCalories[dateKey] ?? 0;
        
        // Get dynamic weekday name based on actual date
        String dayName = DateFormat('E').format(date).substring(0, 1);
        
        return GestureDetector(
          onTap: () => _onDateSelected(date),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    color: isSelected ? Colors.blue : 
                           isToday ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  calories > 0 ? calories.toInt().toString() : '',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : 
                           isToday ? Colors.white : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  calories > 0 ? 'kcal' : '',
                  style: TextStyle(
                    color: isSelected ? Colors.blue : 
                           isToday ? Colors.white : Colors.grey,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : 
                           isToday ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : 
                             isToday ? Colors.blue : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : 
                               isToday ? Colors.blue : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCaloriesSummary() {
    double progress = todayTotalCalories / targetCalories;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM dd').format(selectedDate),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress > 1 ? 1 : progress,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                todayTotalCalories.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / ${targetCalories.toInt()}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Center(
            child: Text(
              'kcal',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMM dd').format(selectedDate),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (todayMeals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'No meals recorded for this day',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ...todayMeals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(MealGroup meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '• ${meal.mealType}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...meal.foods.map((food) => _buildFoodItem(food)),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                food.icon ?? '🍽️',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (food.portion != null)
                  Text(
                    food.portion!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '+${food.calories.toInt()} kcal',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}