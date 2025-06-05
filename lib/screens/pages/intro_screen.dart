import 'package:flutter/material.dart';
import '../../models/user_data.dart';
import '../pages/login_page.dart'; 

class WelcomePage extends StatefulWidget {
  final UserData userData;
  final VoidCallback onChanged;

  const WelcomePage({
    Key? key,
    required this.userData,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
   
    _controller = TextEditingController(text: widget.userData.firstName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 42, 42, 42),
          title: Text(
            'Back to Login?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to go back to login? Your progress will be lost.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate back to login page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                'Yes, Go Back',
                style: TextStyle(color: Color(0xFF007AFF)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Text(
          'Welcome',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            Text(
              'First, what can we call you?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "We'd like to get to know you.",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Preferred first name',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _controller,
              onChanged: (value) {
                widget.userData.updateFirstName(value.trim());
                widget.onChanged();
              },
              style: TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF007AFF)),
                ),
                filled: true,
                fillColor: Color(0xFF363B59), 
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            Spacer(),
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 1), 
              child: OutlinedButton(
                onPressed: _goBackToLogin,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xFF007AFF),
                  side: BorderSide(color: const Color.fromARGB(255, 92, 91, 91)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15), 
                ),
                child: Text(
                  'Back to Login',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}