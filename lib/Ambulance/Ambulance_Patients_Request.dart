import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../firestore_service.dart';

class PatientRequestsScreen extends StatefulWidget {
  const PatientRequestsScreen({super.key});

  @override
  State<PatientRequestsScreen> createState() => _PatientRequestsScreenState();
}

class _PatientRequestsScreenState extends State<PatientRequestsScreen> {
  String? _selectedAmbulanceId;
  String? _selectedAmbulanceDriver;
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        title: Text(
          'Patient Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                value: _filterStatus,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                items: ['all', 'pending', 'assigned', 'completed', 'cancelled']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: _filterStatus == 'all'
            ? firestoreService.getPatientRequests().map(
                (snapshot) => snapshot.docs,
              )
            : firestoreService.getPatientRequests().map((snapshot) {
                return snapshot.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == _filterStatus;
                }).toList();
              }),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _centerMessage(
              MdiIcons.alertCircle,
              'Error loading requests',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return _centerMessage(
              MdiIcons.accountOff,
              'No patient requests available',
            );
          }
          final docs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final geoPoint = data['location'] as GeoPoint?;
              final pickupLocation = geoPoint != null
                  ? LatLng(geoPoint.latitude, geoPoint.longitude)
                  : null;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Name and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                data['patientName'],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Chip(
                            avatar: Icon(
                              _getStatusIcon(data['status']),
                              size: 18,
                              color: _getStatusColor(data['status']),
                            ),
                            label: Text(
                              data['status'].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: _getStatusColor(data['status']),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: _getStatusColor(
                              data['status'],
                            ).withOpacity(0.15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _infoRow(Icons.cake, 'Age: ${data['patientAge']}'),
                      _infoRow(
                        Icons.local_hospital,
                        'Condition: ${data['condition']}',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.apartment,
                        'Hospital: ${data['hospitalName']}',
                      ),
                      if (pickupLocation != null)
                        _infoRow(
                          Icons.location_on,
                          'Pickup: ${pickupLocation.latitude.toStringAsFixed(4)}, '
                          '${pickupLocation.longitude.toStringAsFixed(4)}',
                        ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.access_time,
                        'Created: ${data['createdAt']?.toDate().toString().substring(0, 16) ?? 'Unknown'}',
                        size: 12,
                      ),
                      const SizedBox(height: 12),
                      // Actions
                      if (data['status'] == 'pending')
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.local_shipping),
                            label: const Text('Assign Ambulance'),
                            onPressed: () => _showAmbulanceAssignmentDialog(
                              context,
                              doc.id,
                              data['patientName'],
                              data['hospitalId'],
                              data['hospitalName'],
                              pickupLocation ?? const LatLng(0, 0),
                            ),
                          ),
                        ),
                      if (data['status'] == 'assigned')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _infoRow(
                              Icons.person_pin,
                              'Assigned to: ${data['assignedAmbulanceDriver'] ?? 'Unknown'}',
                              alignRight: true,
                            ),
                            _infoRow(
                              Icons.confirmation_number,
                              'Ambulance: ${data['assignedAmbulanceId']}',
                              size: 12,
                              alignRight: true,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('Reassign'),
                                  onPressed: () => _reassignAmbulance(
                                    context,
                                    doc.id,
                                    data['assignedAmbulanceId'],
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () =>
                                      _cancelAssignment(context, doc.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _centerMessage(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text, {
    double size = 14,
    bool alignRight = false,
  }) {
    return Row(
      mainAxisAlignment: alignRight
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Icon(icon, size: size + 4, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: size, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'assigned':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _reassignAmbulance(
    BuildContext context,
    String requestId,
    String currentAmbulanceId,
  ) async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final ambulancesSnapshot = await firestoreService
        .getAvailableAmbulances()
        .first;

    if (!mounted) return;

    if (ambulancesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No available ambulances')));
      return;
    }

    final ambulances = ambulancesSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'driverName': data['driverName'],
        'ambulanceNumber': data['ambulanceNumber'],
      };
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Reassign Ambulance'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Current assignment will be cancelled'),
                    const Text('Select a new ambulance:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAmbulanceId,
                      hint: const Text('Select Ambulance'),
                      items: ambulances.map((ambulance) {
                        return DropdownMenuItem<String>(
                          value: ambulance['id'],
                          child: Text(
                            '${ambulance['driverName']} (${ambulance['ambulanceNumber']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAmbulanceId = value;
                          _selectedAmbulanceDriver = ambulances.firstWhere(
                            (a) => a['id'] == value,
                          )['driverName'];
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedAmbulanceId == null
                      ? null
                      : () async {
                          try {
                            // First cancel current assignment
                            await firestoreService.updatePatientRequestStatus(
                              requestId,
                              'pending',
                            );

                            // Then assign to new ambulance
                            final requestSnapshot = await firestoreService
                                .getPatientRequest(requestId);
                            final requestData =
                                requestSnapshot.data() as Map<String, dynamic>;

                            await firestoreService.assignAmbulanceToRequest(
                              requestId: requestId,
                              ambulanceId: _selectedAmbulanceId!,
                              ambulanceDriver: _selectedAmbulanceDriver!,
                              patientName: requestData['patientName'],
                              hospitalId: requestData['hospitalId'],
                              hospitalName: requestData['hospitalName'],
                              pickupLocation: requestData['location'],
                            );

                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ambulance reassigned successfully!',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error reassigning ambulance: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text('Confirm Reassignment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cancelAssignment(BuildContext context, String requestId) async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Assignment'),
        content: const Text('Are you sure you want to cancel this assignment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestoreService.updatePatientRequestStatus(
                requestId,
                'cancelled',
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Assignment cancelled')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAmbulanceAssignmentDialog(
    BuildContext context,
    String requestId,
    String patientName,
    String hospitalId,
    String hospitalName,
    LatLng pickupLocation,
  ) async {
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );
    final ambulancesSnapshot = await firestoreService
        .getAvailableAmbulances()
        .first;

    if (!mounted) return;

    if (ambulancesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No available ambulances')));
      return;
    }

    final ambulances = ambulancesSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'driverName': data['driverName'],
        'ambulanceNumber': data['ambulanceNumber'],
      };
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Ambulance'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select an available ambulance:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAmbulanceId,
                      hint: const Text('Select Ambulance'),
                      items: ambulances.map((ambulance) {
                        return DropdownMenuItem<String>(
                          value: ambulance['id'],
                          child: Text(
                            '${ambulance['driverName']} (${ambulance['ambulanceNumber']})',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAmbulanceId = value;
                          _selectedAmbulanceDriver = ambulances.firstWhere(
                            (a) => a['id'] == value,
                          )['driverName'];
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedAmbulanceId == null
                      ? null
                      : () async {
                          try {
                            await firestoreService.assignAmbulanceToRequest(
                              requestId: requestId,
                              ambulanceId: _selectedAmbulanceId!,
                              ambulanceDriver: _selectedAmbulanceDriver!,
                              patientName: patientName,
                              hospitalId: hospitalId,
                              hospitalName: hospitalName,
                              pickupLocation: GeoPoint(
                                pickupLocation.latitude,
                                pickupLocation.longitude,
                              ),
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ambulance assigned successfully!',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error assigning ambulance: ${e.toString()}',
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text('Confirm Assignment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
