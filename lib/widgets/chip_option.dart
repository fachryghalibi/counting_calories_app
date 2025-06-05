import 'package:flutter/material.dart';

class ChipOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSpecial;

  const ChipOption({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isSpecial = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isSpecial ? Color(0xFF007AFF) : Color.fromARGB(255, 81, 89, 174))
              : Color(0xFF363B59),
          border: Border.all(
            color: isSelected 
                ? (isSpecial ? Color(0xFF007AFF) : Colors.grey[600]!)
                : Color(0xFF363B59),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected && isSpecial ? Colors.white : Colors.grey[300],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check,
                  color: isSpecial ? Colors.white : Color.fromARGB(255, 68, 255, 0),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}