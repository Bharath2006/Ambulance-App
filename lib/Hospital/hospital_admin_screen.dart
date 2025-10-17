import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../firestore_service.dart';

class HospitalAdminScreen extends StatefulWidget {
  const HospitalAdminScreen({super.key});

  @override
  State<HospitalAdminScreen> createState() => _HospitalAdminScreenState();
}

class _HospitalAdminScreenState extends State<HospitalAdminScreen> {
  String? _selectedHospitalId;
  final FirestoreService _firestoreService = FirestoreService();
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceVariant.withOpacity(0.1),
      appBar: AppBar(
        title: Text(
          '🏥 Hospital Admin',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: colors.primaryContainer,
      ),
      body: Column(
        children: [
          // Hospital Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getHospitals(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Error loading hospitals');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<String>(
                  value: _selectedHospitalId,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.local_hospital,
                      color: Colors.redAccent,
                    ),
                    labelText: 'Select Hospital',
                    labelStyle: GoogleFonts.poppins(),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: document.id,
                      child: Text(
                        data['name'],
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedHospitalId = value;
                    });
                  },
                );
              },
            ),
          ),

          // Modern Tab Switch
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                _buildTabButton('🚨 Alerts', 0, colors),
                _buildTabButton('🧍 Patients', 1, colors),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: _selectedHospitalId == null
                ? Center(
                    child: Text(
                      'Please select a hospital to view details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : _currentTabIndex == 0
                ? _buildAlertsTab()
                : _buildPatientsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index, ColorScheme colors) {
    bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: index == 0
                ? const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  )
                : const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isActive ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getHospitalAlerts(_selectedHospitalId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading alerts');
        if (snapshot.connectionState == ConnectionState.waiting)
          return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No incoming ambulances 🚑',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: const Icon(
                  Icons.local_shipping,
                  color: Colors.redAccent,
                  size: 32,
                ),
                title: Text(
                  'Ambulance: ${data['ambulanceId']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusChip(
                      'ETA: ${data['eta']} min',
                      Colors.blueAccent,
                    ),
                    _buildStatusChip(
                      'Status: ${data['status']}',
                      Colors.orangeAccent,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () => _showAmbulanceDetails(data),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPatientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getHospitalPatients(_selectedHospitalId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading patients');
        if (snapshot.connectionState == ConnectionState.waiting)
          return const CircularProgressIndicator();
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No patient records found',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.teal, size: 32),
                title: Text(
                  data['patientName'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Age: ${data['patientAge']}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    _buildStatusChip(data['condition'], Colors.purpleAccent),
                    _buildStatusChip(data['status'], Colors.greenAccent),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () => _showPatientDetails(data),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  void _showAmbulanceDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🚑 Ambulance ${data['ambulanceId']}',
          style: GoogleFonts.poppins(),
        ),
        content: Text(
          'ETA: ${data['eta']} min\nStatus: ${data['status']}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['patientName'], style: GoogleFonts.poppins()),
        content: Text(
          'Age: ${data['patientAge']}\nCondition: ${data['condition']}\nStatus: ${data['status']}\nHospital: ${data['hospitalName']}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
