// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// import 'firestore_service.dart';

// class PatientListScreen extends StatefulWidget {
//   const PatientListScreen({super.key});

//   @override
//   State<PatientListScreen> createState() => _PatientListScreenState();
// }

// class _PatientListScreenState extends State<PatientListScreen> {
//   final _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Patient List'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => setState(() {}),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search patients...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 suffixIcon: _searchQuery.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           _searchController.clear();
//                           setState(() => _searchQuery = '');
//                         },
//                       )
//                     : null,
//               ),
//               onChanged: (value) =>
//                   setState(() => _searchQuery = value.toLowerCase()),
//             ),
//           ),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirestoreService().getAllAmbulancesWithPatients(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(
//                           Icons.error_outline,
//                           color: Colors.red,
//                           size: 60,
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             'Error loading patients\n${snapshot.error}',
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(color: Colors.red),
//                           ),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => setState(() {}),
//                           child: const Text('Retry'),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.people_alt_outlined, size: 60),
//                         Text(
//                           'No patients found',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 final filteredDocs = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final name =
//                       data['patientName']?.toString().toLowerCase() ?? '';
//                   final condition =
//                       data['patientCondition']?.toString().toLowerCase() ?? '';
//                   final ambulanceId = doc.id.toLowerCase();

//                   return name.contains(_searchQuery) ||
//                       condition.contains(_searchQuery) ||
//                       ambulanceId.contains(_searchQuery);
//                 }).toList();

//                 if (filteredDocs.isEmpty) {
//                   return const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.search_off, size: 60),
//                         Text(
//                           'No matching patients found',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: filteredDocs.length,
//                   itemBuilder: (context, index) {
//                     final document = filteredDocs[index];
//                     final data = document.data() as Map<String, dynamic>;
//                     final timestamp = data['timestamp'] as Timestamp?;
//                     final formattedTime = timestamp != null
//                         ? DateFormat(
//                             'MMM dd, yyyy - hh:mm a',
//                           ).format(timestamp.toDate())
//                         : 'Time not available';

//                     return Card(
//                       margin: const EdgeInsets.symmetric(
//                         horizontal: 8.0,
//                         vertical: 4.0,
//                       ),
//                       elevation: 2,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(10),
//                         onTap: () {
//                           // Add navigation to patient details if needed
//                         },
//                         child: Padding(
//                           padding: const EdgeInsets.all(12.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Flexible(
//                                     child: Text(
//                                       data['patientName'] ?? 'No name provided',
//                                       style: const TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                   Chip(
//                                     label: Text(
//                                       data['status']
//                                               ?.toString()
//                                               .toUpperCase() ??
//                                           'UNKNOWN',
//                                       style: const TextStyle(fontSize: 12),
//                                     ),
//                                     backgroundColor: _getStatusColor(
//                                       data['status']?.toString(),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Condition: ${data['patientCondition'] ?? 'Not specified'}',
//                                 style: const TextStyle(fontSize: 16),
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   Icon(Icons.drive_eta_rounded, size: 16),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     'Ambulance ID: ${document.id}',
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   const Icon(Icons.access_time, size: 16),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     'Last updated: $formattedTime',
//                                     style: const TextStyle(fontSize: 14),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStatusColor(String? status) {
//     switch (status?.toLowerCase()) {
//       case 'active':
//         return Colors.blue[200]!;
//       case 'critical':
//         return Colors.red[200]!;
//       case 'stable':
//         return Colors.green[200]!;
//       case 'completed':
//         return Colors.grey[300]!;
//       default:
//         return Colors.orange[200]!;
//     }
//   }
// }
