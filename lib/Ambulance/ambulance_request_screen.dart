import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../firestore_service.dart';
import 'ambulance_provider.dart';

class AmbulanceRequestScreen extends StatefulWidget {
  const AmbulanceRequestScreen({super.key});

  @override
  State<AmbulanceRequestScreen> createState() => _AmbulanceRequestScreenState();
}

class _AmbulanceRequestScreenState extends State<AmbulanceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String _patientCondition = 'stable';
  String? _selectedHospitalId;

  Color primaryColor = const Color(0xFF1976D2);
  Color accentColor = const Color(0xFF42A5F5);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final ambulanceProvider = Provider.of<AmbulanceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Request Ambulance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _patientNameController,
                    label: 'Patient Name',
                    icon: Icons.person,
                  ),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                  ),
                  _buildConditionSelector(),
                  const SizedBox(height: 20),
                  Text(
                    'Select Hospital',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: firestoreService.getHospitals(),
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
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text('Select Hospital'),
                        items: snapshot.data!.docs.map((
                          DocumentSnapshot document,
                        ) {
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: document.id,
                            child: Text(
                              data['name'],
                              style: GoogleFonts.poppins(),
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
                  const SizedBox(height: 25),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        'Request Ambulance',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate() &&
                            _selectedHospitalId != null) {
                          await firestoreService.createAmbulanceRequest(
                            patientName: _patientNameController.text,
                            address: _addressController.text,
                            condition: _patientCondition,
                            hospitalId: _selectedHospitalId!,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Ambulance requested!'),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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

  Widget _buildConditionSelector() {
    List<Map<String, dynamic>> conditions = [
      {'label': 'Stable', 'value': 'stable', 'color': Colors.green},
      {'label': 'Urgent', 'value': 'urgent', 'color': Colors.orange},
      {'label': 'Critical', 'value': 'critical', 'color': Colors.red},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Condition',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: conditions.map((cond) {
            bool selected = _patientCondition == cond['value'];
            return ChoiceChip(
              label: Text(
                cond['label'],
                style: GoogleFonts.poppins(
                  color: selected ? Colors.white : cond['color'],
                  fontWeight: FontWeight.w500,
                ),
              ),
              selectedColor: cond['color'],
              backgroundColor: cond['color'].withOpacity(0.2),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _patientCondition = cond['value'];
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
