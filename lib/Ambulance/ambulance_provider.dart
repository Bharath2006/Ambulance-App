import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class AmbulanceProvider with ChangeNotifier {
  LatLng? _currentLocation;
  LatLng? _hospitalLocation;
  String _ambulanceId = 'AMB-${DateTime.now().millisecondsSinceEpoch}';
  String _patientName = '';
  String _patientCondition = 'stable';
  List<LatLng> _routeCoordinates = [];
  double _estimatedTime = 0;
  double _distance = 0;
  bool _signalOverrideActive = false;
  String? _currentIntersectionId;

  // New fields for driver and assignment management
  String _driverId = '';
  String _driverName = '';
  String? _currentAssignmentId;
  String _hospitalName = '';
  String _hospitalId = '';

  // Getters
  LatLng? get currentLocation => _currentLocation;
  LatLng? get hospitalLocation => _hospitalLocation;
  String get ambulanceId => _ambulanceId;
  String get patientName => _patientName;
  String get patientCondition => _patientCondition;
  List<LatLng> get routeCoordinates => _routeCoordinates;
  double get estimatedTime => _estimatedTime;
  double get distance => _distance;
  bool get signalOverrideActive => _signalOverrideActive;
  String? get currentIntersectionId => _currentIntersectionId;

  // New getters
  String get driverId => _driverId;
  String get driverName => _driverName;
  String? get currentAssignmentId => _currentAssignmentId;
  String get hospitalName => _hospitalName;
  String get hospitalId => _hospitalId;

  void setCurrentLocation(LatLng location) {
    _currentLocation = location;
    notifyListeners();
  }

  void setHospitalLocation(LatLng location) {
    _hospitalLocation = location;
    notifyListeners();
  }

  void setPatientDetails(String name, String condition) {
    _patientName = name;
    _patientCondition = condition;
    notifyListeners();
  }

  void setRouteDetails(List<LatLng> coordinates, double time, double distance) {
    _routeCoordinates = coordinates;
    _estimatedTime = time;
    _distance = distance;
    notifyListeners();
  }

  void setSignalOverrideStatus(bool status, {String? intersectionId}) {
    _signalOverrideActive = status;
    _currentIntersectionId = intersectionId;
    notifyListeners();
  }

  // New methods for driver and assignment management
  void setDriverDetails(String driverId, String driverName) {
    _driverId = driverId;
    _driverName = driverName;
    notifyListeners();
  }

  void setAssignmentDetails({
    required String assignmentId,
    required String hospitalId,
    required String hospitalName,
  }) {
    _currentAssignmentId = assignmentId;
    _hospitalId = hospitalId;
    _hospitalName = hospitalName;
    notifyListeners();
  }

  void clearRoute() {
    _routeCoordinates = [];
    _estimatedTime = 0;
    _distance = 0;
    _signalOverrideActive = false;
    _currentIntersectionId = null;
    notifyListeners();
  }

  void clearAssignment() {
    _currentAssignmentId = null;
    _hospitalId = '';
    _hospitalName = '';
    notifyListeners();
  }
}
