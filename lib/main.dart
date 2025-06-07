// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'screens/welcome_screen.dart'; // No longer the direct home
import 'auth_gate.dart'; // <<--- IMPORT AuthGate
// import 'constants/app_styles.dart';
// import 'constants/app_colors.dart';

const supabaseUrl =
    'https://nmpouoybdywwalngwrqm.supabase.co'; // From your Supabase project settings
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tcG91b3liZHl3d2Fsbmd3cnFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNTI5ODAsImV4cCI6MjA2NDcyODk4MH0.gRv96hqLmFODGb3b4Flb7yQ8yEMKcgZakVwmeVuVzbM'; // From your Supabase project settings

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const CMCApp());
}

final supabase = Supabase.instance.client; // Global Supabase client

class CMCApp extends StatelessWidget {
  const CMCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EternalSpace CMC',
      theme: ThemeData(
        // ... Your existing theme data ...
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // <<--- USE AuthGate as home
    );
  }
}
