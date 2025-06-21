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
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('🔍 === SESSION CHECK DEBUG ===');
    print('🔍 All stored keys: ${prefs.getKeys().toList()}');
    print('🔍 isLoggedIn: ${prefs.getBool('isLoggedIn')}');
    
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userId = prefs.getInt('id');
      final userName = prefs.getString('full_name') ?? 'User';
      
      // ✅ PERBAIKAN: Ambil completedOnboarding sebagai boolean dari SharedPreferences
      final completedOnboarding = prefs.getBool('completedOnboarding') ?? false;
      
      print('🔍 User ID: $userId');
      print('🔍 User name: $userName');
      print('🔍 completedOnboarding (boolean): $completedOnboarding');
      print('🔍 ===============================');
      
      if (context.mounted) {
        if (completedOnboarding) {
          print('✅ User $userId already completed onboarding, navigating to home');
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          print('⚠️ User $userId logged in but onboarding not completed, navigating to onboarding');
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
    
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: keyboardHeight > 0 ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40),
                      _buildHeader(),
                      SizedBox(height: 40),
                      _buildLoginForm(),
                      SizedBox(height: 16),
                      _buildRememberMeSection(),
                      SizedBox(height: 24),
                      _buildLoginButton(),
                      SizedBox(height: 16),
                      _buildForgotPasswordButton(),
                      SizedBox(height: 24),
                      _buildDivider(),
                      SizedBox(height: 20),
                      _buildSocialLoginButtons(),
                      Spacer(),
                      _buildSignUpSection(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Sign in to continue your health journey',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 15,
          ),
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
          SizedBox(height: 16),
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
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
        filled: true,
        fillColor: Color(0xFF363B59),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Color(0xFF363B59),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF007AFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          scale: 0.9,
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
            side: BorderSide(color: Colors.grey[400]!),
          ),
        ),
        Text(
          'Remember me',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF007AFF),
          disabledBackgroundColor: Color(0xFF007AFF).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // ✅ DIPERBAIKI: Login method dengan pengecekan completedOnboarding dari database
   // ✅ DEBUG VERSION: Login method dengan logging lengkap
Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _loginService.login(_email, _password);
      
      // ✅ DEBUG: Print seluruh response dari API
      print('🔍 ===== FULL API RESPONSE DEBUG =====');
      print('🔍 Full response: ${response.toString()}');
      print('🔍 Response type: ${response.runtimeType}');
      print('🔍 Success: ${response['success']}');
      
      if (response['data'] != null) {
        print('🔍 Data: ${response['data'].toString()}');
        
        if (response['data']['user'] != null) {
          print('🔍 User data: ${response['data']['user'].toString()}');
          
          final userData = response['data']['user'];
          
          // ✅ DEBUG: Print semua field yang mungkin berisi onboarding status
          print('🔍 ----- ONBOARDING FIELDS DEBUG -----');
          print('🔍 completedOnboarding: ${userData['completedOnboarding']}');
          print('🔍 =====================================');
        }
      }
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        
        // Save credentials
        await _saveCredentials();

        // Extract user data
        final userData = response['data']['user'] ?? response['data'];

        if (userData != null) {
          final id = userData['id'] ?? 0;
          final username = userData['username'] ?? userData['full_name'] ?? 'User';
          
          // ✅ COMPREHENSIVE CHECK: Cek semua kemungkinan field name
          dynamic onboardingValue;
          
          // Cek berbagai kemungkinan nama field
          final possibleFields = [
            'completedOnboarding'
          ];
          
          for (String field in possibleFields) {
            if (userData[field] != null) {
              onboardingValue = userData[field];
              print('✅ Found onboarding field: $field = $onboardingValue');
              break;
            }
          }
          
          // Jika tidak ada field yang ditemukan, default ke false
          if (onboardingValue == null) {
            print('⚠️ No onboarding field found in response, defaulting to false');
            onboardingValue = false;
          }
          
          // ✅ ROBUST CONVERSION: Handle berbagai tipe data
          bool completedOnboarding = false;
          
          if (onboardingValue is bool) {
            completedOnboarding = onboardingValue;
          } else if (onboardingValue is int) {
            completedOnboarding = onboardingValue == 1;
          } else if (onboardingValue is String) {
            completedOnboarding = (onboardingValue.toLowerCase() == 'true' || 
                                 onboardingValue == '1' || 
                                 onboardingValue.toLowerCase() == 'completed');
          } else {
            print('⚠️ Unknown onboarding value type: ${onboardingValue.runtimeType}');
          }
          
          print('✅ Login successful for user: $username (ID: $id)');
          print('✅ Raw onboarding value: $onboardingValue (${onboardingValue.runtimeType})');
          print('✅ Converted to boolean: $completedOnboarding');

          // Save essential data
          await prefs.setInt('id', id);
          await prefs.setString('full_name', username);
          await prefs.setBool('completedOnboarding', completedOnboarding);
          await prefs.setBool('isLoggedIn', true);

          // Save token if available
          if (response['data']['token'] != null) {
            await prefs.setString('auth_token', response['data']['token']);
          }

          // ✅ NAVIGATION dengan override untuk testing
          if (context.mounted) {
            
            // 🔧 TEMPORARY OVERRIDE UNTUK TESTING (hapus setelah API diperbaiki)
            // Uncomment baris di bawah untuk force navigate ke home sementara
            // print('🔧 OVERRIDE: Force navigating to home for testing');
            // Navigator.pushReplacementNamed(context, '/home');
            // return;
            
            if (completedOnboarding) {
              print('✅ Onboarding completed → Navigate to Home');
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              print('⚠️ Onboarding not completed → Navigate to Onboarding');
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: _isLoading ? Colors.grey : Color(0xFF007AFF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[600],
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[600],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        _buildSocialButton(
          'Continue with Google',
          Icons.g_mobiledata,
          Colors.white,
          Colors.black,
          _handleGoogleLogin,
        ),
        SizedBox(height: 10),
        _buildSocialButton(
          'Continue with Apple',
          Icons.apple,
          Colors.black,
          Colors.white,
          _handleAppleLogin,
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withOpacity(0.6),
          side: BorderSide(color: Colors.grey[600]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _isLoading ? textColor.withOpacity(0.6) : textColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: _isLoading ? textColor.withOpacity(0.6) : textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
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
                fontSize: 14,
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

  void _handleGoogleLogin() {
    // Implementasi Google login
  }

  void _handleAppleLogin() {
    // Implementasi Apple login
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