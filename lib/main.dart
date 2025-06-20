import 'package:aplikasi_counting_calories/screens/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_counting_calories/screens/pages/login_page.dart';
import 'package:aplikasi_counting_calories/screens/pages/register_screen.dart';
import 'package:aplikasi_counting_calories/screens/onboarding_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Determine the initial route based on user session
  String initialRoute = await _determineInitialRoute();
  
  runApp(MyApp(initialRoute: initialRoute));
}

// Function to determine which screen to show initially
Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  
  print('🔍 === MAIN APP SESSION CHECK ===');
  print('🔍 All stored keys: ${prefs.getKeys().toList()}');
  print('🔍 isLoggedIn: ${prefs.getBool('isLoggedIn')}');
  print('🔍 onboarding_completed: ${prefs.getBool('onboarding_completed')}');
  print('🔍 full_name: ${prefs.getString('full_name')}');
  print('🔍 email: ${prefs.getString('email')}');
  print('🔍 ===============================');
  
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final isOnboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  print('Is logged in: $isLoggedIn');
  print('Is onboarding completed: $isOnboardingCompleted');

  if (isLoggedIn) {
    if (isOnboardingCompleted) {
      // User sudah login dan sudah menyelesaikan onboarding -> langsung ke home
      print('✅ User already completed onboarding, navigating to home');
      return '/home';
    } else {
      // User sudah login tapi belum menyelesaikan onboarding -> ke onboarding
      print('⚠️ User logged in but onboarding not completed, navigating to onboarding');
      return '/onboarding';
    }
  } else {
    // User belum login -> ke login page
    print('🔐 No existing session found, navigating to login');
    return '/login';
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({Key? key, required this.initialRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Counting Calories App',
      // Set initial route based on session check
      initialRoute: initialRoute,
      // Define all routes
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterScreen(),
        '/onboarding': (context) => OnboardingFlow(),
        '/home': (context) => MainNavigationWrapper(),
        // Tambahkan route lain sesuai kebutuhan
        // '/profile': (context) => ProfilePage(),
      },
      // Fallback untuk route yang tidak ditemukan
      onUnknownRoute: (settings) {
        print('❌ Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => LoginPage(),
        );
      },
    );
  }
}