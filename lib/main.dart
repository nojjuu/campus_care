
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings/settings_page.dart';
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

final GlobalKey<ScaffoldState> homeShellScaffoldKey =
GlobalKey<ScaffoldState>();

class HomeShell extends StatefulWidget {
const HomeShell({super.key});


@override
State<HomeShell> createState() => _HomeShellState();
}



class CampusCareMenuButton extends StatelessWidget {
const CampusCareMenuButton({super.key});

@override
Widget build(BuildContext context) {
return IconButton(
tooltip: 'Open navigation menu',
icon: const Icon(
Icons.menu,
color: Color(0xFF17243B),
),
onPressed: () {
homeShellScaffoldKey.currentState?.openDrawer();
},
);
}
}


class _HomeShellState extends State<HomeShell> {
// Page indexes: Home = 0, Appointments = 1, Health = 2, Profile = 3.
// The central Book navigation item is an action that opens a new route.
int _index = 0;


Widget _buildCampusCareDrawer() {
final user = FirebaseAuth.instance.currentUser;
final displayName = user?.displayName?.trim().isNotEmpty == true
? user!.displayName!
    : (user?.email?.split('@').first ?? 'Student');

return Drawer(
width: 270,
backgroundColor: Colors.white,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.zero,
),
child: SafeArea(
child: Column(
children: [
// Header
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 12, 22),
child: Row(
children: [
Container(
width: 35,
height: 35,
decoration: BoxDecoration(
color: const Color(0xFF00846F),
borderRadius: BorderRadius.circular(11),
),
child: const Icon(
Icons.add,
color: Colors.white,
size: 29,
),
),
const SizedBox(width: 10),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'CampusCare',
style: TextStyle(
fontWeight: FontWeight.w800,
fontSize: 15,
color: Color(0xFF17243B),
),
),
SizedBox(height: 2),
Text(
'STUDENT HEALTH & WELLNESS',
style: TextStyle(
fontSize: 7,
letterSpacing: 0.5,
color: Color(0xFF526784),
),
),
],
),
),
IconButton(
tooltip: 'Close menu',
onPressed: () => Navigator.pop(context),
icon: const Icon(Icons.close, size: 19),
),
],
),
),

const Padding(
padding: EdgeInsets.symmetric(horizontal: 20),
child: Align(
alignment: Alignment.centerLeft,
child: Text(
'YOUR CAMPUS COMPANION',
style: TextStyle(
fontSize: 9,
letterSpacing: 0.7,
fontWeight: FontWeight.w700,
color: Color(0xFF71819A),
),
),
),
),
const SizedBox(height: 12),

// Main navigation
_drawerItem(
icon: Icons.home_outlined,
title: 'Home',
selected: _index == 0,
onTap: () => _drawerNavigate(0),
),
_drawerItem(
icon: Icons.calendar_month_outlined,
title: 'Appointments',
selected: _index == 1,
onTap: () => _drawerNavigate(1),
),
_drawerItem(
icon: Icons.add,
title: 'Book appointment',
selected: false,
onTap: () {
Navigator.pop(context);
_openBooking();
},
),
_drawerItem(
icon: Icons.favorite_border,
title: 'Health information',
selected: _index == 2,
onTap: () => _drawerNavigate(2),
),
_drawerItem(
icon: Icons.person_outline,
title: 'My profile',
selected: _index == 3,
onTap: () => _drawerNavigate(3),
),

// Wellness reminder
Padding(
padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color: const Color(0xFFFBFCFE),
border: Border.all(
color: const Color(0xFFE4EAF2),
),
borderRadius: BorderRadius.circular(13),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.verified_user_outlined,
color: Color(0xFF00846F),
size: 19,
),
const SizedBox(height: 9),
const Text(
'A little care, every day.',
style: TextStyle(
fontSize: 11,
fontWeight: FontWeight.w800,
color: Color(0xFF17243B),
),
),
const SizedBox(height: 5),
const Text(
'Your well-being comes first.',
style: TextStyle(
fontSize: 10,
color: Color(0xFF71819A),
),
),
const SizedBox(height: 12),
InkWell(
onTap: () => _drawerNavigate(3),
child: const Padding(
padding: EdgeInsets.symmetric(vertical: 4),
child: Text(
'Keep your profile up to date ↗',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
color: Color(0xFF00846F),
),
),
),
),
],
),
),
),

const Spacer(),

// Bottom menu
_drawerItem(
icon: Icons.settings_outlined,
title: 'Settings',
selected: false,
onTap: () {
Navigator.pop(context); // Close the drawer first.
_openSettings(); // Open the actual Settings screen.
},
),
_drawerItem(
icon: Icons.logout,
title: 'Log out',
selected: false,
onTap: () async {
Navigator.pop(context);
await FirebaseAuth.instance.signOut();
},
),

const Divider(
height: 16,
indent: 14,
endIndent: 14,
color: Color(0xFFE7EDF3),
),

// Signed-in user
InkWell(
onTap: () => _drawerNavigate(3),
child: Padding(
padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
child: Row(
children: [
const CircleAvatar(
radius: 15,
backgroundColor: Color(0xFFDDF5EF),
child: Icon(
Icons.person_outline,
color: Color(0xFF00846F),
size: 18,
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
displayName,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w600,
color: Color(0xFF26364D),
),
),
Text(
user?.email ?? 'CampusCare student',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 9,
color: Color(0xFF71819A),
),
),
],
),
),
const Icon(
Icons.chevron_right,
color: Color(0xFF71819A),
size: 20,
),
],
),
),
),
],
),
),
);
}

Widget _drawerItem({
required IconData icon,
required String title,
required bool selected,
required VoidCallback onTap,
bool highlighted = false,
}) {
final active = selected || highlighted;

return Padding(
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 2,
),
child: Material(
color: active
? const Color(0xFFDDF5EF)
    : Colors.transparent,
borderRadius: BorderRadius.circular(12),
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: onTap,
child: SizedBox(
height: 38,
child: Row(
children: [
const SizedBox(width: 12),
Icon(
icon,
size: 17,
color: active
? const Color(0xFF00846F)
    : const Color(0xFF425572),
),
const SizedBox(width: 13),
Text(
title,
style: TextStyle(
fontSize: 11,
fontWeight: active
? FontWeight.w700
    : FontWeight.w400,
color: active
? const Color(0xFF007765)
    : const Color(0xFF425572),
),
),
],
),
),
),
),
);
}

void _drawerNavigate(int index) {
Navigator.pop(context);
_selectPage(index);
}


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

void _openSettings() {
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => const CampusCareSettingsPage(),
),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
key: homeShellScaffoldKey,
drawer: _buildCampusCareDrawer(),
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
AppointmentsScreen(
onProfile: () => _selectPage(3)
),
HealthPage(
onProfile: () => _selectPage(3)
),
StudentProfilePage(
onHealth: () => _selectPage(2),
),
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

