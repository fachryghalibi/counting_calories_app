import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D2D44),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[400],
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 0 ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_outlined,
                color: currentIndex == 0 ? Colors.white : Colors.grey[400],
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 30,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentIndex == 1
                    ? Colors.blue
                    : Colors.transparent,
                border: Border.all(
                  color: currentIndex == 1
                      ? Colors.blue
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: currentIndex == 1
                    ? Colors.white
                    : Colors.grey[400],
              ),
            ),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 2 ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history_outlined,
                color: currentIndex == 2 ? Colors.white : Colors.grey[400],
              ),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 3 ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: currentIndex == 3 ? Colors.white : Colors.grey[400],
              ),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
