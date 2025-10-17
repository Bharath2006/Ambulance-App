import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Ambulance/ambulance_provider.dart';
import 'firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientAgeController = TextEditingController();
  final TextEditingController _patientConditionController =
      TextEditingController();

  String? _selectedHospitalId;
  String? _selectedHospitalName;
  bool _isLoading = true;
  String? _errorMessage;
  late MapController _mapController;
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeLocation();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final snapshot = await firestoreService.getHospitals().first;

      setState(() {
        _hospitals = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Hospital',
            'address': data['address'] ?? 'No address available',
            'location': data['location'],
          };
        }).toList();
      });
    } catch (e) {
      _showSnack('Error loading hospitals: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        final newStatus = await Geolocator.requestPermission();
        if (newStatus != LocationPermission.whileInUse &&
            newStatus != LocationPermission.always) {
          setState(() {
            _errorMessage = 'Location permission required';
            _isLoading = false;
          });
          return;
        }
      }

      await _updateCurrentLocation();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      Provider.of<AmbulanceProvider>(
        context,
        listen: false,
      ).setCurrentLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      _showSnack('Error updating location: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showHospitalSelectionDialog() async {
    if (_hospitals.isEmpty) {
      _showSnack('No hospitals available');
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: _hospitals.length,
          itemBuilder: (context, index) {
            final hospital = _hospitals[index];
            return ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.red),
              title: Text(hospital['name']),
              subtitle: Text(hospital['address']),
              onTap: () {
                setState(() {
                  _selectedHospitalId = hospital['id'];
                  _selectedHospitalName = hospital['name'];
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _submitPatientRequest() async {
    if (_formKey.currentState!.validate() && _selectedHospitalId != null) {
      try {
        final firestoreService = Provider.of<FirestoreService>(
          context,
          listen: false,
        );
        final provider = Provider.of<AmbulanceProvider>(context, listen: false);

        final currentLocation = provider.currentLocation;
        if (currentLocation == null)
          throw Exception('Current location not available');

        await firestoreService.createPatientRequest(
          patientName: _patientNameController.text,
          patientAge: _patientAgeController.text,
          condition: _patientConditionController.text,
          hospitalId: _selectedHospitalId!,
          hospitalName: _selectedHospitalName!,
          location: currentLocation,
        );

        _showSnack('Patient request submitted successfully!');

        _patientNameController.clear();
        _patientAgeController.clear();
        _patientConditionController.clear();
        setState(() {
          _selectedHospitalId = null;
          _selectedHospitalName = null;
        });
      } catch (e) {
        _showSnack('Error submitting request: $e');
      }
    } else if (_selectedHospitalId == null) {
      _showSnack('Please select a hospital');
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.red),
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🚑 Patient Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _patientNameController,
                decoration: _inputDecoration('Patient Name', Icons.person),
                validator: (value) =>
                    value!.isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patientAgeController,
                decoration: _inputDecoration('Patient Age', Icons.cake),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Enter patient age' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patientConditionController,
                decoration: _inputDecoration(
                  'Patient Condition',
                  Icons.medical_services,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Describe patient condition' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showHospitalSelectionDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_hospital, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedHospitalName ?? 'Select Hospital',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedHospitalName != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'REQUEST AMBULANCE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  onPressed: _submitPatientRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 300,
                  child: Consumer<AmbulanceProvider>(
                    builder: (context, provider, _) {
                      return FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              provider.currentLocation ?? const LatLng(0, 0),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          if (provider.currentLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: provider.currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.person_pin_circle,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          if (_selectedHospitalId != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    (_hospitals.firstWhere(
                                              (h) =>
                                                  h['id'] ==
                                                  _selectedHospitalId,
                                            )['location']
                                            as GeoPoint)
                                        .latitude,
                                    (_hospitals.firstWhere(
                                              (h) =>
                                                  h['id'] ==
                                                  _selectedHospitalId,
                                            )['location']
                                            as GeoPoint)
                                        .longitude,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.local_hospital,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
