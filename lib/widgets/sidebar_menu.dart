import 'package:flutter/material.dart';

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF219653); // Green
    const activeBg = Color(0xFFEAFBF3); // Light green
    const inactiveColor = Color(0xFF6D758F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
          child: Text(
            "Accounts",
            style: TextStyle(
              color: activeColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        _SidebarItem(
          icon: Icons.emoji_people,
          label: "Farm Worker",
          isActive: selectedIndex == 0,
          activeColor: activeColor,
          activeBg: activeBg,
          inactiveColor: inactiveColor,
          onTap: () => onTap(0),
        ),
        _SidebarItem(
          icon: Icons.groups,
          label: "Technician",
          isActive: selectedIndex == 1,
          activeColor: activeColor,
          activeBg: activeBg,
          inactiveColor: inactiveColor,
          onTap: () => onTap(1),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? activeBg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: isActive ? activeColor : inactiveColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
