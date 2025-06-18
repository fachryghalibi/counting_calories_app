import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:aplikasi_counting_calories/service/register_service.dart'; 

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Loading state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4A90E2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Register',
          style: TextStyle(
            color: Color(0xFF4A90E2),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  
                  // Header
                  Text(
                    'Create your account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Join thousands of users tracking their fitness goals',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // Email Field
                  _buildFieldLabel('Email Address'),
                  SizedBox(height: 8),
                  _buildEmailField(),
                  SizedBox(height: 24),
                  
                  // Password Field
                  _buildFieldLabel('Password'),
                  SizedBox(height: 8),
                  _buildPasswordField(),
                  SizedBox(height: 40),
                  
                  // Create Account Button
                  _buildCreateAccountButton(),
                  SizedBox(height: 24),
                  
                  // OR Divider
                  _buildOrDivider(),
                  SizedBox(height: 24),
                  
                  // Google Login Button
                  _buildGoogleLoginButton(),
                  SizedBox(height: 32),
                  
                  // Terms and Privacy
                  _buildTermsAndPrivacy(),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_isLoading, // Disable when loading
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address';
        }
        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        _emailFocusNode.unfocus();
        FocusScope.of(context).requestFocus(_passwordFocusNode);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFF2A2A3E),
        hintText: 'Enter your email address',
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: _emailFocusNode.hasFocus ? Color(0xFF4A90E2) : Colors.white38,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      enabled: !_isLoading, // Disable when loading
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        _passwordFocusNode.unfocus();
        _handleCreateAccount();
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFF2A2A3E),
        hintText: 'Enter your password',
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: _passwordFocusNode.hasFocus ? Color(0xFF4A90E2) : Colors.white38,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white38,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        errorStyle: TextStyle(
          color: Colors.redAccent,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateAccount, // Disable when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? Colors.grey : Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: Color(0xFF4A90E2).withOpacity(0.3),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white30, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.white30, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleLogin, // Disable when loading
        icon: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            color: _isLoading ? Colors.grey : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: _isLoading ? Colors.grey : Colors.white30, 
            width: 1.5
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: 'By creating an account, you agree to our ',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
      try {
        final result = await RegisterService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (result['success']) {
          // Show success message
          _showSnackBar(
            message: result['message'],
            isError: false,
            icon: Icons.check_circle,
          );
          
          // Navigate to login page after success
          Future.delayed(Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          });
        } else {
          // Show error message
          _showSnackBar(
            message: result['message'],
            isError: true,
            icon: Icons.error_outline,
          );
        }
      } catch (e) {
        _showSnackBar(
          message: 'An unexpected error occurred. Please try again.',
          isError: true,
          icon: Icons.error_outline,
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleLogin() {
    _showSnackBar(
      message: 'Google login will be implemented soon',
      isError: false,
      icon: Icons.info_outline,
      backgroundColor: Colors.orange,
    );
  }

  void _showSnackBar({
    required String message,
    required bool isError,
    required IconData icon,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? (isError ? Colors.redAccent : Color(0xFF4A90E2)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}