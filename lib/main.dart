import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'Ambulance/ambulance_driver_view.dart';
import 'Ambulance/ambulance_provider.dart';
import 'Ambulance/ambulance_request_screen.dart';
import 'firebase_options.dart';
import 'firestore_service.dart';
import 'home_screen.dart';
import 'Ambulance/Ambulance_Patients_Request.dart';
import 'route_screen.dart';
import 'admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AmbulanceProvider()),
        Provider(create: (_) => FirestoreService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ambulance Traffic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/request': (context) => const AmbulanceRequestScreen(),
        '/route': (context) => const RouteScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        '/patient-requests': (context) => const PatientRequestsScreen(),
      },
    );
  }
}
