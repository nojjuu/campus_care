import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appointments/appointment_form_screen.dart';
import 'appointments/appointments_screen.dart';
import 'appointments/notification_service.dart';
import 'auth/account_page.dart';
import 'auth/auth_service.dart';
import 'auth/landing_page.dart';
import 'firebase_options.dart';
import 'health/health_page.dart';
import 'home/home_page.dart';
import 'profile/profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00846F)),
        scaffoldBackgroundColor: const Color(0xFFF3F9F5),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return const Scaffold(body: Center(child: Text('Authentication error')));
        }
        if (snap.hasData) return const HomeShell();
        return const LandingPage();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Page indexes: Home = 0, Appointments = 1, Health = 2, Profile = 3.
  // The central Book navigation item is an action that opens a new route.
  int _index = 0;

  void _selectPage(int index) => setState(() => _index = index);

  Future<void> _openBooking() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppointmentFormScreen()),
    );
    // AppointmentService streams update Home and Appointments automatically.
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(
            onAppointments: () => _selectPage(1),
            onBook: _openBooking,
            onHealth: () => _selectPage(2),
            onProfile: () => _selectPage(3),
            onAccount: _openAccount,
          ),
          AppointmentsScreen(),
          const HealthPage(),
          const StudentProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index >= 2 ? _index + 1 : _index,
        onDestinationSelected: (i) {
          if (i == 2) {
            _openBooking();
          } else {
            _selectPage(i > 2 ? i - 1 : i);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.add_circle, color: Color(0xFF00846F), size: 31),
              label: 'Book'),
          NavigationDestination(icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
