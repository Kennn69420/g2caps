import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: Color(0xFFFF8E00),
      unselectedItemColor: Color(0xFF002347),
      selectedItemColor: Color(0xFF249EA0),
      items: [
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.home, 0),
          label: 'Object',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.map, 1),
          label: 'Map',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.qr_code_scanner, 2),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.translate, 3),
          label: 'Translator',
        ),
        BottomNavigationBarItem(
          icon: _buildAnimatedIcon(Icons.library_add_check_outlined, 4),
          label: 'To-Do',
        ),
      ],
    );
  }

  // Method to build an animated icon based on the selected index
  Widget _buildAnimatedIcon(IconData iconData, int itemIndex) {
    bool isSelected = currentIndex == itemIndex;

    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: isSelected ? 70 : 60, // Animate width
        height: isSelected ? 70 : 60, // Animate height
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF249EA0).withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            iconData,
            size: isSelected ? 40 : 25, // Animate icon size
            color: isSelected ? Color(0xFF249EA0) : Color(0xFF002347),
          ),
        ),
      ),
    );
  }
}
