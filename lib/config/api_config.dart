import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ApiConfig {
  // Base URL for the Laravel backend
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // For web
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api'; // For Android Emulator
    } else {
      return 'http://localhost:8000/api'; // For iOS Simulator and others
    }
  }

  // API Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static const String me = '/me';

  // Technician endpoints
  static const String technicians = '/technicians';
  static const String technicianTrashed = '/technicians/trashed';
  static const String technicianRestore = '/technicians/{id}/restore';
  static const String technicianForceDelete = '/technicians/{id}/force';

  // Farm Worker endpoints
  static const String farmWorkers = '/farm-workers';
  static const String farmWorkerTrashed = '/farm-workers/trashed';
  static const String farmWorkerRestore = '/farm-workers/{id}/restore';
  static const String farmWorkerForceDelete = '/farm-workers/{id}/force';

  // Helper method to get full URL
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // Helper method to replace path parameters
  static String replacePathParams(
      String endpoint, Map<String, dynamic> params) {
    String result = endpoint;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}

class SidebarMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const SidebarMenu(
      {super.key, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF219653); // Green
    const activeBg = Color(0xFFEAFBF3); // Light green
    const inactiveColor = Color(0xFF6D758F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
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
