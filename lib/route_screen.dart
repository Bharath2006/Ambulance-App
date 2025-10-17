import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'Ambulance/ambulance_provider.dart';
import 'firestore_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => RouteScreenState();
}

class RouteScreenState extends State<RouteScreen> {
  late final MapController _mapController;
  Timer? _locationUpdateTimer;
  LatLng? _pickupLocation;
  LatLng? _hospitalLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _startLocationUpdates();
    _loadAssignmentDetails();
  }

  void _loadAssignmentDetails() {
    final provider = Provider.of<AmbulanceProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    firestoreService.getAmbulanceByDriverId(provider.driverId).listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final assignment = data['currentAssignment'] as Map<String, dynamic>?;

        if (assignment != null) {
          final pickup = assignment['pickupLocation'] as GeoPoint;
          final hospital = assignment['hospitalLocation'] as GeoPoint;

          provider.setAssignmentDetails(
            assignmentId: assignment['requestId'],
            hospitalId: assignment['hospitalId'],
            hospitalName: assignment['hospitalName'],
          );
          provider.setPatientDetails(
            assignment['patientName'],
            assignment['patientCondition'] ?? 'stable',
          );

          setState(() {
            _pickupLocation = LatLng(pickup.latitude, pickup.longitude);
            _hospitalLocation = LatLng(hospital.latitude, hospital.longitude);
          });

          provider.setHospitalLocation(_hospitalLocation!);
        }
      }
    });
  }

  void _startLocationUpdates() {
    final provider = Provider.of<AmbulanceProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    // Update immediately
    _updateAmbulanceLocation(provider, firestoreService);

    // Then update every 40 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) => _updateAmbulanceLocation(provider, firestoreService),
    );
  }

  Future<void> _updateAmbulanceLocation(
    AmbulanceProvider provider,
    FirestoreService firestoreService,
  ) async {
    if (provider.currentLocation != null) {
      await firestoreService.updateAmbulanceLocation(
        provider.ambulanceId,
        provider.currentLocation!,
      );
    }
  }

  Future<void> _completeAssignment() async {
    final provider = Provider.of<AmbulanceProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    try {
      await firestoreService.completeAssignment(
        provider.ambulanceId,
        provider.currentAssignmentId!,
      );
      provider.clearRoute();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing assignment: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AmbulanceProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ambulance Route'),
            actions: [
              if (provider.currentAssignmentId != null)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _completeAssignment,
                  tooltip: 'Complete Assignment',
                ),
            ],
          ),
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: provider.currentLocation ?? const LatLng(0, 0),
                  initialZoom: 15,
                  onMapReady: () {
                    if (_pickupLocation != null && _hospitalLocation != null) {
                      _mapController.fitCamera(
                        CameraFit.bounds(
                          bounds: LatLngBounds(
                            _pickupLocation!,
                            _hospitalLocation!,
                          ),
                          padding: const EdgeInsets.all(50),
                        ),
                      );
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ambulance_traffic',
                  ),
                  MarkerLayer(
                    markers: [
                      if (provider.currentLocation != null)
                        Marker(
                          point: provider.currentLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      if (_pickupLocation != null)
                        Marker(
                          point: _pickupLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      if (_hospitalLocation != null)
                        Marker(
                          point: _hospitalLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                  if (_pickupLocation != null &&
                      _hospitalLocation != null &&
                      provider.currentLocation != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [
                            _pickupLocation!,
                            provider.currentLocation!,
                            _hospitalLocation!,
                          ],
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ambulance: ${provider.ambulanceId}'),
                        Text('Driver: ${provider.driverName}'),
                        const SizedBox(height: 10),
                        if (provider.currentAssignmentId != null) ...[
                          Text('Patient: ${provider.patientName}'),
                          Text(
                            'Condition: ${provider.patientCondition.toUpperCase()}',
                          ),
                          const SizedBox(height: 10),
                          Text('Hospital: ${provider.hospitalName}'),
                          const SizedBox(height: 10),
                          Text(
                            'Estimated Time: ${provider.estimatedTime.toStringAsFixed(1)} mins',
                          ),
                          Text(
                            'Distance: ${provider.distance.toStringAsFixed(1)} km',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
