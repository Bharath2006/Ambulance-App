import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import 'Ambulance/ambulance_driver_view.dart';
import 'firestore_service.dart';
import 'Hospital/hospital_admin_screen.dart';
import 'Hospital/hospital_management_screen.dart';
import 'patient_list_screen.dart';
import 'Ambulance/ambulance_management_screen.dart';
import 'Ambulance/Ambulance_Patients_Request.dart'; // Add this import

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // void _showDriverSelectionDialog(BuildContext context) async {
  //   final firestoreService = Provider.of<FirestoreService>(
  //     context,
  //     listen: false,
  //   );
  //   final snapshot = await firestoreService.getAmbulances().first;

  //   if (!context.mounted) return;

  //   final drivers = snapshot.docs.map((doc) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     return {
  //       'id': doc.id,
  //       'name': data['driverName'],
  //       'ambulance': data['ambulanceNumber'],
  //     };
  //   }).toList();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Select Driver'),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         child: ListView.builder(
  //           shrinkWrap: true,
  //           itemCount: drivers.length,
  //           itemBuilder: (context, index) {
  //             return ListTile(
  //               title: Text(drivers[index]['name']),
  //               subtitle: Text(drivers[index]['ambulance']),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) =>
  //                         AmbulanceDriverView(driverId: drivers[index]['id']),
  //                   ),
  //                 );
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HospitalManagementScreen(),
                  ),
                );
              },
              child: const Text('Manage Hospitals'),
            ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const PatientListScreen(),
            //       ),
            //     );
            //   },
            //   child: const Text('View All Patients'),
            // ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HospitalAdminScreen(),
                  ),
                );
              },
              child: const Text('Hospital Admin View'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AmbulanceManagementScreen(),
                  ),
                );
              },
              child: const Text('Manage Ambulances'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientRequestsScreen(),
                  ),
                );
              },
              child: const Text('View Patient Requests'),
            ),
            // ElevatedButton(
            //   onPressed: () => _showDriverSelectionDialog(context),
            //   child: const Text('View Ambulance Driver'),
            // ),
          ],
        ),
      ),
    );
  }
}
