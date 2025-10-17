import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Hospital/hospital_management_screen.dart';
import 'Hospital/hospital_admin_screen.dart';
import 'Ambulance/ambulance_management_screen.dart';
import 'Ambulance/Ambulance_Patients_Request.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final List<_MenuItem> menuItems = [
    _MenuItem(
      title: "Manage Hospitals",
      icon: Icons.local_hospital_rounded,
      color: Colors.redAccent,
      page: const HospitalManagementScreen(),
    ),
    _MenuItem(
      title: "Hospital Admin View",
      icon: Icons.admin_panel_settings_rounded,
      color: Colors.blueAccent,
      page: const HospitalAdminScreen(),
    ),
    _MenuItem(
      title: "Manage Ambulances",
      icon: Icons.local_shipping_rounded,
      color: Colors.green,
      page: const AmbulanceManagementScreen(),
    ),
    _MenuItem(
      title: "Patient Requests",
      icon: Icons.people_alt_rounded,
      color: Colors.orangeAccent,
      page: const PatientRequestsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Text(
            "Admin Dashboard",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item.page),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: item.color.withOpacity(0.15),
                      child: Icon(item.icon, size: 32, color: item.color),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });
}
