import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:latlong2/latlong.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> createPatientRequest({
    required String patientName,
    required String patientAge,
    required String condition,
    required String hospitalId,
    required String hospitalName,
    required LatLng location,
  }) async {
    final patientData = {
      'patientName': patientName,
      'patientAge': patientAge,
      'condition': condition,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'location': GeoPoint(location.latitude, location.longitude),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to patient_requests collection
    await _firestore.collection('patient_requests').add(patientData);

    // Also add to hospital's patients subcollection
    await _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('patients')
        .add(patientData);
  }

  Future<DocumentSnapshot> getPatientRequest(String requestId) async {
    return await _firestore.collection('patient_requests').doc(requestId).get();
  }

  Future<void> updateDriverStatus(String driverId, String status) async {
    await _firestore
        .collection('ambulances')
        .where('driverId', isEqualTo: driverId)
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({
              'driverStatus': status,
              'lastStatusUpdate': FieldValue.serverTimestamp(),
            });
          }
        });
  }

  Stream<DocumentSnapshot> getDriverStatus(String driverId) {
    return _firestore
        .collection('ambulances')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs.first);
  }

  Future<void> addAmbulance(
    String driverName,
    String ambulanceNumber,
    String phoneNumber, {
    required String driverId,
  }) async {
    await _firestore.collection('ambulances').add({
      'driverName': driverName,
      'driverId': driverId,
      'ambulanceNumber': ambulanceNumber,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'available',
      'driverStatus': 'available',
    });
  }

  Future<void> assignAmbulanceToRequest({
    required String requestId,
    required String ambulanceId,
    required String ambulanceDriver,
    required String patientName,
    required String hospitalId,
    required String hospitalName,
    required GeoPoint pickupLocation,
  }) async {
    final batch = _firestore.batch();

    // Update the patient request
    final requestRef = _firestore.collection('patient_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'assigned',
      'assignedAmbulanceId': ambulanceId,
      'assignedAmbulanceDriver': ambulanceDriver,
      'assignedAt': FieldValue.serverTimestamp(),
    });

    // Update the ambulance
    final ambulanceRef = _firestore.collection('ambulances').doc(ambulanceId);
    batch.update(ambulanceRef, {
      'status': 'assigned',
      'currentAssignment': {
        'requestId': requestId,
        'patientName': patientName,
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'pickupLocation': pickupLocation,
        'assignedAt': FieldValue.serverTimestamp(),
      },
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> getAvailableAmbulances() {
    return _firestore
        .collection('ambulances')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  Stream<DocumentSnapshot> getAmbulanceByDriverId(String driverId) {
    return _firestore
        .collection('ambulances')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) => snapshot.docs.first);
  }

  Future<void> completeAssignment(String ambulanceId, String requestId) async {
    final batch = _firestore.batch();

    final ambulanceRef = _firestore.collection('ambulances').doc(ambulanceId);
    batch.update(ambulanceRef, {
      'status': 'available',
      'currentAssignment': FieldValue.delete(),
    });

    // Update the request
    final requestRef = _firestore.collection('patient_requests').doc(requestId);
    batch.update(requestRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateAmbulanceLocation(
    String ambulanceId,
    LatLng location,
  ) async {
    await _firestore.collection('ambulances').doc(ambulanceId).set({
      'location': GeoPoint(location.latitude, location.longitude),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getHospitalPatients(String hospitalId) {
    return _firestore
        .collection('hospitals')
        .doc(hospitalId)
        .collection('patients')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getHospitals() {
    return _firestore.collection('hospitals').snapshots();
  }

  Stream<QuerySnapshot> getPatientRequests() {
    return _firestore
        .collection('patient_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updatePatientRequestStatus(
    String requestId,
    String status,
  ) async {
    await _firestore.collection('patient_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getNearbyHospitals(
    GeoPoint location,
    double radiusInKm,
  ) {
    double lat = location.latitude;
    double lng = location.longitude;
    double distanceInLat = radiusInKm / 111.32; // approx km per degree latitude
    double distanceInLng = distanceInLat / cos(lat * (3.1416 / 180));

    GeoPoint lowerBound = GeoPoint(lat - distanceInLat, lng - distanceInLng);
    GeoPoint upperBound = GeoPoint(lat + distanceInLat, lng + distanceInLng);

    return _firestore
        .collection('hospitals')
        .where('location', isGreaterThan: lowerBound)
        .where('location', isLessThan: upperBound)
        .snapshots();
  }

  Future<void> updatePatientDetails(
    String ambulanceId,
    String name,
    String condition,
  ) async {
    await _firestore.collection('ambulances').doc(ambulanceId).update({
      'patientName': name,
      'patientCondition': condition,
    });
  }

  Future<void> requestSignalOverride(
    String intersectionId,
    String ambulanceId,
  ) async {
    await _firestore.collection('signal_overrides').doc(intersectionId).set({
      'ambulanceId': ambulanceId,
      'requestTime': FieldValue.serverTimestamp(),
      'status': 'pending',
      'duration': 120, // 2 minutes override
    });
  }

  Future<void> sendEmergencyAlert(
    String hospitalId,
    String ambulanceId,
    int eta,
  ) async {
    await _firestore.collection('hospital_alerts').doc(hospitalId).set({
      'ambulanceId': ambulanceId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'incoming',
      'eta': eta,
    });
  }

  Future<String> getFCMToken() async {
    await _messaging.requestPermission();
    return await _messaging.getToken() ?? '';
  }

  Stream<DocumentSnapshot> getAmbulanceStream(String ambulanceId) {
    return _firestore.collection('ambulances').doc(ambulanceId).snapshots();
  }

  Stream<DocumentSnapshot> getSignalOverrideStream(String intersectionId) {
    return _firestore
        .collection('signal_overrides')
        .doc(intersectionId)
        .snapshots();
  }

  Future<void> createAmbulanceRequest({
    required String patientName,
    required String address,
    required String condition,
    required String hospitalId,
  }) async {
    await _firestore.collection('ambulance_requests').add({
      'patientName': patientName,
      'address': address,
      'condition': condition,
      'hospitalId': hospitalId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getDriverTrips(String driverId) {
    return _firestore
        .collection('patient_requests')
        .where('assignedAmbulanceDriverId', isEqualTo: driverId)
        .orderBy('assignedAt', descending: true)
        .snapshots();
  }

  Future<void> updateAmbulanceStatus(
    String ambulanceId,
    String status, {
    bool clearPatient = false,
  }) async {
    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (clearPatient) {
      updateData['currentPatient'] = FieldValue.delete();
    }

    await _firestore
        .collection('ambulances')
        .doc(ambulanceId)
        .update(updateData);
  }

  Stream<QuerySnapshot> getAmbulances() {
    return _firestore
        .collection('ambulances')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteAmbulance(String ambulanceId) async {
    await _firestore.collection('ambulances').doc(ambulanceId).delete();
  }

  Stream<QuerySnapshot> getAmbulanceRequests() {
    return _firestore
        .collection('ambulance_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addHospital(String name, String address, LatLng location) async {
    await _firestore.collection('hospitals').add({
      'name': name,
      'address': address,
      'location': GeoPoint(location.latitude, location.longitude),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteHospital(String hospitalId) async {
    await _firestore.collection('hospitals').doc(hospitalId).delete();
  }

  Stream<QuerySnapshot> getHospitalAlerts(String hospitalId) {
    return _firestore
        .collection('hospital_alerts')
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllAmbulancesWithPatients() {
    return _firestore
        .collection('ambulances')
        .where('patientName', isNotEqualTo: null)
        .snapshots();
  }

  Stream<QuerySnapshot> getNearbyIntersections(
    GeoPoint location,
    double radiusInKm,
  ) {
    double lat = location.latitude;
    double lng = location.longitude;
    double distanceInLat = radiusInKm / 111.32; // approx km per degree latitude
    double distanceInLng = distanceInLat / cos(lat * (3.1416 / 180));

    GeoPoint lowerBound = GeoPoint(lat - distanceInLat, lng - distanceInLng);
    GeoPoint upperBound = GeoPoint(lat + distanceInLat, lng + distanceInLng);

    return _firestore
        .collection('intersections')
        .where('location', isGreaterThan: lowerBound)
        .where('location', isLessThan: upperBound)
        .snapshots();
  }
}
