import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../firestore_service.dart';

class AmbulanceManagementScreen extends StatefulWidget {
  const AmbulanceManagementScreen({super.key});

  @override
  State<AmbulanceManagementScreen> createState() =>
      _AmbulanceManagementScreenState();
}

class _AmbulanceManagementScreenState extends State<AmbulanceManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _ambulanceNumberController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _driverIdController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  Color primaryColor = const Color(0xFF1976D2); // Blue
  Color accentColor = const Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        title: Text(
          'Ambulance Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            _buildAddAmbulanceTile(),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ambulance Fleet',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildAmbulanceList()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAmbulanceTile() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        leading: const Icon(Icons.add_circle_outline, color: Colors.green),
        title: Text(
          'Add New Ambulance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                    _driverNameController,
                    'Driver Name',
                    Icons.person,
                  ),
                  _buildTextField(
                    _driverIdController,
                    'Driver ID',
                    Icons.badge,
                  ),
                  _buildTextField(
                    _ambulanceNumberController,
                    'Ambulance Number',
                    Icons.local_shipping,
                  ),
                  _buildTextField(
                    _phoneNumberController,
                    'Phone Number',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _firestoreService.addAmbulance(
                          _driverNameController.text,
                          _ambulanceNumberController.text,
                          _phoneNumberController.text,
                          driverId: _driverIdController.text,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Ambulance added successfully'),
                          ),
                        );
                        _driverNameController.clear();
                        _ambulanceNumberController.clear();
                        _phoneNumberController.clear();
                        _driverIdController.clear();
                      }
                    },
                    label: Text(
                      'Add Ambulance',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildAmbulanceList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getAmbulances(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading ambulances'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No ambulances available',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildAmbulanceCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAmbulanceCard(String id, Map<String, dynamic> data) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: accentColor,
          child: const Icon(
            Icons.local_hospital,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          data['driverName'],
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚑 Ambulance: ${data['ambulanceNumber']}',
              style: GoogleFonts.poppins(),
            ),
            Text(
              '📞 Phone: ${data['phoneNumber']}',
              style: GoogleFonts.poppins(),
            ),
            _buildStatusBadge(data['status'] ?? 'unknown'),
            if (data['currentAssignment'] != null)
              Text(
                '📋 Assigned to: ${(data['currentAssignment'] as Map)['patientName']}',
                style: GoogleFonts.poppins(color: Colors.blue),
              ),
          ],
        ),
        trailing: Column(
          children: [
            DropdownButton<String>(
              value: data['status'] ?? 'available',
              items: ['available', 'assigned', 'maintenance', 'off-duty']
                  .map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  )
                  .toList(),
              onChanged: (value) =>
                  _firestoreService.updateAmbulanceStatus(id, value!),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, id),
            ),
          ],
        ),
        onTap: () => _showAmbulanceDetails(context, data, id),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status) {
      case 'available':
        badgeColor = Colors.green;
        break;
      case 'assigned':
        badgeColor = Colors.orange;
        break;
      case 'maintenance':
        badgeColor = Colors.blueGrey;
        break;
      case 'off-duty':
        badgeColor = Colors.grey;
        break;
      default:
        badgeColor = Colors.black45;
    }
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String ambulanceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this ambulance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firestoreService.deleteAmbulance(ambulanceId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🚨 Ambulance deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAmbulanceDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String ambulanceId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Ambulance Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👨‍✈ Driver: ${data['driverName']}'),
            Text('🚑 Ambulance #: ${data['ambulanceNumber']}'),
            Text('📞 Phone: ${data['phoneNumber']}'),
            _buildStatusBadge(data['status'] ?? 'unknown'),
            const SizedBox(height: 14),
            if (data['currentAssignment'] != null) ...[
              const Text(
                '📝 Current Assignment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Patient: ${(data['currentAssignment'] as Map)['patientName']}',
              ),
              Text(
                'Hospital: ${(data['currentAssignment'] as Map)['hospitalName']}',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.done_all),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _firestoreService.completeAssignment(
                    ambulanceId,
                    (data['currentAssignment'] as Map)['requestId'],
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Assignment completed')),
                  );
                },
                label: const Text('Force Complete Assignment'),
              ),
            ],
          ],
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
