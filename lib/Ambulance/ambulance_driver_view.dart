// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:provider/provider.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_map/flutter_map.dart';

// import '../firestore_service.dart';
// import 'ambulance_provider.dart';

// class AmbulanceDriverView extends StatefulWidget {
//   final String driverId;
//   const AmbulanceDriverView({super.key, required this.driverId});

//   @override
//   State<AmbulanceDriverView> createState() => _AmbulanceDriverViewState();
// }

// class _AmbulanceDriverViewState extends State<AmbulanceDriverView> {
//   late MapController _mapController;
//   LatLng? _pickupLocation;
//   LatLng? _hospitalLocation;
//   String _driverStatus = 'available';

//   @override
//   void initState() {
//     super.initState();
//     _mapController = MapController();
//     _loadDriverStatus();
//   }

//   Future<void> _loadDriverStatus() async {
//     final firestoreService = Provider.of<FirestoreService>(
//       context,
//       listen: false,
//     );
//     final statusSnapshot = await firestoreService
//         .getDriverStatus(widget.driverId)
//         .first;
//     if (statusSnapshot.exists) {
//       setState(() {
//         _driverStatus = statusSnapshot['driverStatus'] ?? 'available';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final firestoreService = Provider.of<FirestoreService>(context);
//     final ambulanceProvider = Provider.of<AmbulanceProvider>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Ambulance Driver Dashboard'),
//         actions: [
//           DropdownButton<String>(
//             value: _driverStatus,
//             items: ['available', 'on-duty', 'on-break', 'off-duty']
//                 .map(
//                   (status) => DropdownMenuItem(
//                     value: status,
//                     child: Text(status.toUpperCase()),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (value) async {
//               await firestoreService.updateDriverStatus(
//                 widget.driverId,
//                 value!,
//               );
//               setState(() {
//                 _driverStatus = value;
//               });
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: firestoreService.getAmbulanceByDriverId(widget.driverId),
//         builder: (context, ambulanceSnapshot) {
//           if (ambulanceSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (!ambulanceSnapshot.hasData || !ambulanceSnapshot.data!.exists) {
//             return const Center(child: Text('Driver not found'));
//           }

//           final ambulanceData =
//               ambulanceSnapshot.data!.data() as Map<String, dynamic>;
//           final currentAssignment =
//               ambulanceData['currentAssignment'] as Map<String, dynamic>?;

//           return StreamBuilder<QuerySnapshot>(
//             stream: firestoreService.getDriverTrips(widget.driverId),
//             builder: (context, tripsSnapshot) {
//               final markers = <Marker>[];

//               // Add current location if available
//               if (ambulanceData['location'] != null) {
//                 final loc = ambulanceData['location'] as GeoPoint;
//                 markers.add(
//                   Marker(
//                     point: LatLng(loc.latitude, loc.longitude),
//                     width: 40,
//                     height: 40,
//                     child: const Icon(
//                       Icons.directions_car,
//                       color: Colors.blue,
//                       size: 40,
//                     ),
//                   ),
//                 );
//               }

//               // Add pickup and hospital locations from current assignment
//               if (currentAssignment != null) {
//                 if (currentAssignment['pickupLocation'] != null) {
//                   final pickup =
//                       currentAssignment['pickupLocation'] as GeoPoint;
//                   _pickupLocation = LatLng(pickup.latitude, pickup.longitude);
//                   markers.add(
//                     Marker(
//                       point: _pickupLocation!,
//                       width: 40,
//                       height: 40,
//                       child: const Icon(
//                         Icons.location_pin,
//                         color: Colors.red,
//                         size: 40,
//                       ),
//                     ),
//                   );
//                 }

//                 if (currentAssignment['hospitalLocation'] != null) {
//                   final hospital =
//                       currentAssignment['hospitalLocation'] as GeoPoint;
//                   _hospitalLocation = LatLng(
//                     hospital.latitude,
//                     hospital.longitude,
//                   );
//                   markers.add(
//                     Marker(
//                       point: _hospitalLocation!,
//                       width: 40,
//                       height: 40,
//                       child: const Icon(
//                         Icons.local_hospital,
//                         color: Colors.green,
//                         size: 40,
//                       ),
//                     ),
//                   );
//                 }
//               }

//               // Center the map on relevant locations
//               if (_pickupLocation != null && _hospitalLocation != null) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   final bounds = LatLngBounds.fromPoints([
//                     _pickupLocation!,
//                     _hospitalLocation!,
//                   ]);
//                   _mapController.fitCamera(
//                     CameraFit.bounds(
//                       bounds: bounds,
//                       padding: const EdgeInsets.all(50),
//                     ),
//                   );
//                 });
//               }

//               return Column(
//                 children: [
//                   // Driver Information Card
//                   Card(
//                     margin: const EdgeInsets.all(16),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             ambulanceData['driverName'] ?? 'Unknown Driver',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             'Ambulance: ${ambulanceData['ambulanceNumber']}',
//                           ),
//                           Text('Status: ${ambulanceData['status']}'),
//                           if (currentAssignment != null) ...[
//                             const SizedBox(height: 16),
//                             const Text(
//                               'Current Assignment:',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             Text(
//                               'Patient: ${currentAssignment['patientName']}',
//                             ),
//                             Text(
//                               'Condition: ${currentAssignment['patientCondition'] ?? 'unknown'}',
//                             ),
//                             Text(
//                               'Hospital: ${currentAssignment['hospitalName']}',
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),

//                   Expanded(
//                     child: FlutterMap(
//                       mapController: _mapController,
//                       options: MapOptions(
//                         initialCenter: const LatLng(0, 0),
//                         initialZoom: 15,
//                       ),
//                       children: [
//                         TileLayer(
//                           urlTemplate:
//                               'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                           subdomains: const ['a', 'b', 'c'],
//                         ),
//                         MarkerLayer(markers: markers),
//                         if (_pickupLocation != null &&
//                             _hospitalLocation != null)
//                           PolylineLayer(
//                             polylines: [
//                               Polyline(
//                                 points: [_pickupLocation!, _hospitalLocation!],
//                                 color: Colors.blue,
//                                 strokeWidth: 4,
//                               ),
//                             ],
//                           ),
//                       ],
//                     ),
//                   ),

//                   // Action Buttons
//                   if (currentAssignment != null)
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton(
//                             onPressed: () async {
//                               await firestoreService.completeAssignment(
//                                 ambulanceSnapshot.data!.id,
//                                 currentAssignment['requestId'],
//                               );
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Assignment completed'),
//                                 ),
//                               );
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.green,
//                             ),
//                             child: const Text('Complete Trip'),
//                           ),
//                           ElevatedButton(
//                             onPressed: () => _showEmergencyOptions(context),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.red,
//                             ),
//                             child: const Text('Emergency'),
//                           ),
//                         ],
//                       ),
//                     ),

//                   // Trip History
//                   if (tripsSnapshot.hasData &&
//                       tripsSnapshot.data!.docs.isNotEmpty)
//                     ExpansionTile(
//                       title: const Text('Trip History'),
//                       children: [
//                         SizedBox(
//                           height: 200,
//                           child: ListView.builder(
//                             itemCount: tripsSnapshot.data!.docs.length,
//                             itemBuilder: (context, index) {
//                               final trip = tripsSnapshot.data!.docs[index];
//                               final tripData =
//                                   trip.data() as Map<String, dynamic>;
//                               return ListTile(
//                                 title: Text(tripData['patientName']),
//                                 subtitle: Text(
//                                   '${tripData['hospitalName']} - ${tripData['status']}',
//                                 ),
//                                 trailing: Text(
//                                   tripData['assignedAt']
//                                           ?.toDate()
//                                           .toString()
//                                           .substring(0, 16) ??
//                                       'Unknown date',
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _showEmergencyOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.warning),
//               title: const Text('Request Signal Override'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _requestSignalOverride(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.local_hospital),
//               title: const Text('Alert Hospital'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _alertHospital(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.medical_services),
//               title: const Text('Update Patient Condition'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _updatePatientCondition(context);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _requestSignalOverride(BuildContext context) {
//     // Implement signal override request
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Request Signal Override'),
//         content: const Text(
//           'Requesting traffic signal override for emergency passage',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Implement actual override request
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Signal override requested')),
//               );
//             },
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _alertHospital(BuildContext context) {
//     // Implement hospital alert
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Alert Hospital'),
//         content: const Text('Sending emergency alert to destination hospital'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Implement actual hospital alert
//               Navigator.pop(context);
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text('Hospital alerted')));
//             },
//             child: const Text('Confirm'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _updatePatientCondition(BuildContext context) {
//     String? selectedCondition;
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: const Text('Update Patient Condition'),
//             content: DropdownButton<String>(
//               value: selectedCondition,
//               hint: const Text('Select condition'),
//               items: ['stable', 'critical', 'deteriorating', 'unconscious']
//                   .map(
//                     (condition) => DropdownMenuItem(
//                       value: condition,
//                       child: Text(condition),
//                     ),
//                   )
//                   .toList(),
//               onChanged: (value) => setState(() => selectedCondition = value),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: selectedCondition == null
//                     ? null
//                     : () {
//                         // Implement condition update
//                         Navigator.pop(context);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Condition updated to $selectedCondition',
//                             ),
//                           ),
//                         );
//                       },
//                 child: const Text('Update'),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
