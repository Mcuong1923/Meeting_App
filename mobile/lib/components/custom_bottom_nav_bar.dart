import 'package:flutter/material.dart';

class BottomNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  BottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<IconData> icons;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          height: 70,
          color: Colors.white,
          child: Stack(
            children: [
              // Custom painter cho hiệu ứng lõm
              Positioned.fill(
                child: CustomPaint(
                  painter: _NavBarPainter(selectedIndex, icons.length),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(icons.length, (index) {
                  final isSelected = index == selectedIndex;
                  return GestureDetector(
                    onTap: () => onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: isSelected ? 56 : 44,
                      height: isSelected ? 56 : 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF25608A)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        icons[index],
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: isSelected ? 28 : 26,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final int selectedIndex;
  final int itemCount;

  _NavBarPainter(this.selectedIndex, this.itemCount);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final double width = size.width;
    final double height = size.height;
    final double itemWidth = width / itemCount;
    final double centerX = itemWidth * (selectedIndex + 0.5);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(centerX - 38, 0)
      ..cubicTo(
        centerX - 18,
        0,
        centerX - 18,
        38,
        centerX,
        38,
      )
      ..cubicTo(
        centerX + 18,
        38,
        centerX + 18,
        0,
        centerX + 38,
        0,
      )
      ..lineTo(width, 0)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBarPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

// Modern icon styles
class ModernIcons {
  static const IconData home = Icons.home_rounded;
  static const IconData calendar = Icons.calendar_today_rounded;
  static const IconData notification = Icons.notifications_rounded;
  static const IconData profile = Icons.person_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData video = Icons.videocam_rounded;
  static const IconData chat = Icons.chat_bubble_rounded;
  static const IconData search = Icons.search_rounded;
}
