import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_rutas_repartidor/Pages/mapa_page.dart';
import 'package:app_rutas_repartidor/Pages/login_page.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cdnzvaetebfurrobbidc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNkbnp2YWV0ZWJmdXJyb2JiaWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExMTMxNTAsImV4cCI6MjA5NjY4OTE1MH0.zRffKJgiGEEfIYXCHluFhOr4LINEC7KEQnb7Ee-_nUU',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rutas Repartidor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = supabase.auth.currentSession;

          // Si no hay sesión → mostrar login
          if (session == null) {
            return const LoginPage();
          }
          // Si hay sesión → mostrar mapa
          return const MapaPage();
        },
      ),
    );
  }
}
