import 'package:aplikasi_counting_calories/screens/pages/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_counting_calories/service/login_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  final LoginService _loginService = LoginService();

  @override
  void initState() {
    super.initState();
    _checkSession();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  

  // ✅ DIPERBAIKI: Cek sesi dengan data dari database
 // ✅ DIPERBAIKI: Cek sesi hanya dari data lokal SharedPreferences
Future<void> _checkSession() async {
  final prefs = await SharedPreferences.getInstance();
  
  print('🔍 === SESSION CHECK DEBUG ===');
  print('🔍 All stored keys: ${prefs.getKeys().toList()}');
  print('🔍 isLoggedIn: ${prefs.getBool('isLoggedIn')}');
  
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn) {
    final userId = prefs.getInt('id');
    final userName = prefs.getString('full_name') ?? 'User';
    
    // ✅ PERBAIKAN: Ambil completedOnboarding hanya dari SharedPreferences lokal
    // yang sudah disimpan oleh method _login()
    final completedOnboarding = prefs.getBool('completedOnboarding') ?? false;
    
    print('🔍 User ID: $userId');
    print('🔍 User name: $userName');
    print('🔍 completedOnboarding (from local SharedPreferences): $completedOnboarding');
    print('🔍 ===============================');
    
    if (context.mounted) {
      if (completedOnboarding) {
        print('✅ User $userId already completed onboarding (local check), navigating to home');
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('⚠️ User $userId logged in but onboarding not completed (local check), navigating to onboarding');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  } else {
    print('❌ No existing session found');
  }
}

  // Load saved credentials - DIPERBAIKI untuk load setiap kali halaman ditampilkan
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    print('🔍 Loading saved credentials:');
    print('🔍 Saved email: $savedEmail');
    print('🔍 Saved password: ${savedPassword != null ? '[HIDDEN]' : 'null'}');
    print('🔍 Remember me: $rememberMe');

    if (savedEmail != null && savedPassword != null && rememberMe) {
      setState(() {
        _email = savedEmail;
        _password = savedPassword;
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
      print('✅ Credentials loaded and fields filled');
    } else {
      print('❌ No saved credentials found or remember me is false');
    }
  }

  // Save credentials - DIPERBAIKI untuk save/clear dengan benar
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
      print('✅ Credentials saved');
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
      print('✅ Credentials cleared');
    }
  }

  // TAMBAHKAN method untuk refresh credentials saat kembali ke halaman
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload credentials setiap kali halaman menjadi visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: keyboardHeight > 0 ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
            child: Container(
              width: screenWidth,
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08, // 8% dari lebar layar
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top spacer untuk balance
                    SizedBox(height: screenHeight * 0.05),
                    
                    // Header section
                    _buildHeader(),
                    
                    SizedBox(height: screenHeight * 0.06),
                    
                    // Form section
                    _buildLoginForm(),
                    
                    SizedBox(height: 20),
                    
                    // Remember me section
                    _buildRememberMeSection(),
                    
                    SizedBox(height: 32),
                    
                    // Login button
                    _buildLoginButton(),
                    
                    SizedBox(height: 20),
                    
                    // Forgot password
                    _buildForgotPasswordButton(),
                    
                    // Flexible spacer
                    SizedBox(height: screenHeight * 0.08),
                    
                    // Sign up section
                    _buildSignUpSection(),
                    
                    // Bottom spacer untuk balance
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'Sign in to continue your health journey',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          SizedBox(height: 20),
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400], size: 22),
        filled: true,
        fillColor: Color(0xFF363B59),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onChanged: (value) => _email = value,
      onSaved: (value) => _email = value!,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _isLoading ? null : _login(),
      style: TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400], size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[400],
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Color(0xFF363B59),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
      onChanged: (value) => _password = value,
      onSaved: (value) => _password = value!,
    );
  }

  Widget _buildRememberMeSection() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
              // Save/clear credentials immediately when checkbox changes
              _saveCredentials();
            },
            activeColor: Color(0xFF007AFF),
            checkColor: Colors.white,
            side: BorderSide(color: Colors.grey[400]!, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Remember me',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF007AFF),
          disabledBackgroundColor: Color(0xFF007AFF).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ✅ DIPERBAIKI: Login method dengan pengecekan completedOnboarding dari database
   Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await _loginService.login(_email, _password);

        if (response['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          
          // Save credentials first
          await _saveCredentials();

          // Extract user data
          Map<String, dynamic>? userData;
          if (response['data'] != null && response['data']['user'] != null) {
            userData = response['data']['user'];
          } else if (response['data'] != null) {
            userData = response['data'];
          }

          if (userData != null) {
            final id = userData['id'] ?? 0;

            // ✅ Ambil username dari response API
            String username = userData['username'] ?? userData['firstName'] ?? userData['full_name'] ?? 'User';
            final email = userData['email'] ?? '';
            final createdAt = userData['createdAt'] ?? userData['created_at'] ?? '';
            final dateOfBirth = userData['dateOfBirth'] ?? userData['date_of_birth'] ?? '';
            final gender = userData['gender'] ?? '';
            final height = (userData['height'] ?? 0).toDouble();
            final weight = (userData['weight'] ?? 0).toDouble();
            final activityLevel = userData['activityLevel'] ?? userData['activity_level'] ?? 0;
            final active = userData['active'] ?? false;
            final profileImage = userData['profileImage'] ?? userData['profile_image'] ?? '';
            
            // ✅ PENTING: Ambil completedOnboarding sebagai boolean dari database
            bool completedOnboarding = false;
            
            // Cek berbagai kemungkinan tipe data dari API
            final onboardingValue = userData['completedOnboarding'] ?? 
                                  userData['completed_onboarding'] ?? 
                                  userData['completedOnBoarding'] ??
                                  userData['onboardingCompleted'] ??
                                  userData['onboarding_completed'];
            
            // ✅ KONVERSI ke boolean dengan handling berbagai tipe data
            if (onboardingValue != null) {
              if (onboardingValue is bool) {
                completedOnboarding = onboardingValue;
              } else if (onboardingValue is int) {
                completedOnboarding = onboardingValue == 1;
              } else if (onboardingValue is String) {
                completedOnboarding = onboardingValue.toLowerCase() == 'true' || onboardingValue == '1';
              }
            }
            
            print('✅ Login successful for user ID: $id');
            print('✅ Username loaded: $username');
            print('✅ completedOnboarding from DB: $onboardingValue (${onboardingValue.runtimeType})');
            print('✅ completedOnboarding converted to boolean: $completedOnboarding');

            // ✅ Simpan data ke SharedPreferences
            await prefs.setInt('id', id);
            await prefs.setString('username_$id', username);
            await prefs.setString('full_name', username);
            await prefs.setString('email', email);
            await prefs.setString('created_at', createdAt);
            await prefs.setString('dateOfBirth', dateOfBirth);
            await prefs.setString('gender', gender);
            await prefs.setDouble('height', height);
            await prefs.setDouble('weight', weight);
            await prefs.setInt('activityLevel', activityLevel);
            await prefs.setBool('active', active);
            await prefs.setString('profileImage', profileImage);
            
            // ✅ PENTING: Simpan completedOnboarding sebagai boolean ke SharedPreferences
            await prefs.setBool('completedOnboarding', completedOnboarding);
            await prefs.setBool('isLoggedIn', true);

            // ✅ Simpan token jika tersedia
            if (response['data']['token'] != null) {
              await prefs.setString('auth_token', response['data']['token']);
            }

            // ✅ Navigasi berdasarkan status onboarding boolean
            if (context.mounted) {
              if (completedOnboarding) {
                print('✅ User $id completed onboarding (boolean: true) → Home');
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                print('⚠️ User $id needs onboarding (boolean: false) → Onboarding');
                Navigator.pushReplacementNamed(context, '/onboarding');
              }
            }
          } else {
            if (context.mounted) {
              _showErrorSnackbar('Invalid response structure');
            }
          }
        } else {
          if (context.mounted) {
            _showErrorSnackbar(response['message'] ?? 'Login failed');
          }
        }
      } catch (e) {
        print('❌ Login error: $e');
        if (context.mounted) {
          _showErrorSnackbar('Network error occurred');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _handleForgotPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: _isLoading ? Colors.grey : Color(0xFF007AFF),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : _handleSignUp,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Color(0xFF007AFF),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleForgotPassword() {
    // Implementasi forgot password
  }

  void _handleSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(),
      ),
    );
  }
}