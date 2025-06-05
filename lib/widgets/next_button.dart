import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLastPage;
  final VoidCallback onPressed;

  const NextButton({
    Key? key,
    required this.isEnabled,
    required this.isLastPage,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 50), 
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            disabledBackgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: Text(
            isLastPage ? 'Get Started' : 'Next',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
